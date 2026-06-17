library(shiny)
library(tidyverse)
library(scales)
library(DT)
library(plotly)
library(bslib)

# ------------------------------------------------------------------
# Données
# ------------------------------------------------------------------
pro <- read_delim(
  "../data/lol_pro_scene_dataset.csv",
  delim = ";",
  locale = locale(decimal_mark = ","),
  show_col_types = FALSE
) %>%
  mutate(
    source = "Pro",
    role = recode(role, "UTILITY" = "SUPPORT"),
    resultat = factor(win, levels = c(0, 1), labels = c("Défaite", "Victoire")),
    wards = wardsplaced,
    vision_score = vision,
    minutes = game_duration / 60
  )

ranked <- read_delim(
  "../data/lol_ranked_dataset.csv",
  delim = ";",
  locale = locale(decimal_mark = ","),
  show_col_types = FALSE
) %>%
  mutate(
    source = "SoloQ",
    role = recode(role, "UTILITY" = "SUPPORT"),
    resultat = factor(win, levels = c(0, 1), labels = c("Défaite", "Victoire")),
    wards = wards_placed,
    vision_score = vision,
    minutes = game_duration / 60
  )

df <- bind_rows(
  pro %>% select(source, role, champion, resultat, win, kills, deaths, assists,
                 kda, gold, cs, damage, vision_score, wards, minutes),
  ranked %>% select(source, role, champion, resultat, win, kills, deaths, assists,
                    kda, gold, cs, damage, vision_score, wards, minutes)
) %>%
  mutate(
    role = factor(role, levels = c("TOP", "JUNGLE", "MIDDLE", "BOTTOM", "SUPPORT")),
    source = factor(source, levels = c("SoloQ", "Pro"))
  )

metric_choices <- c(
  "KDA" = "kda",
  "Kills" = "kills",
  "Deaths" = "deaths",
  "Assists" = "assists",
  "Gold" = "gold",
  "CS" = "cs",
  "Damage" = "damage",
  "Vision score" = "vision_score",
  "Wards" = "wards"
)

# Métriques cumulatives (compteurs)
rate_metrics <- c("kills", "deaths", "assists", "gold", "cs", "damage", "vision_score", "wards")
metrics_common <- c("kda", "kills", "deaths", "assists", "gold", "cs", "damage", "vision_score", "wards")

metric_label <- function(x) names(metric_choices)[match(x, metric_choices)]

# ------------------------------------------------------------------
# Couleurs & thème (cohérent avec le deck : hextech sombre)
# ------------------------------------------------------------------
# Convention : SoloQ = rouge, Pro = bleu (partout où les deux contextes sont comparés)
COL_SOLOQ <- "#E63946"   # rouge -> SoloQ / individuel
COL_PRO   <- "#3B9AE1"   # bleu  -> Pro / collectif
# Dimension victoire/défaite : couleurs distinctes (le rouge est réservé au SoloQ)
COL_WIN   <- "#43AA8B"   # vert
COL_LOSE  <- "#E9A23B"   # ambre
FG        <- "#F0E6D2"
MUTED     <- "#A09B8C"
GRID      <- "#1C2B3A"

theme_lsn <- bs_theme(
  version = 5,
  bg = "#0A1428", fg = FG,
  primary = COL_PRO, secondary = COL_SOLOQ,
  base_font = font_google("Inter"),
  heading_font = font_google("Inter")
)

plot_theme <- theme_minimal(base_size = 13) +
  theme(
    plot.background  = element_rect(fill = "transparent", color = NA),
    panel.background = element_rect(fill = "transparent", color = NA),
    plot.title    = element_text(face = "bold", size = 16, color = FG),
    plot.subtitle = element_text(size = 11, color = MUTED),
    axis.title    = element_text(size = 11, color = FG),
    axis.text     = element_text(size = 10, color = "#C9C2B4"),
    legend.title  = element_text(size = 10, color = FG),
    legend.text   = element_text(size = 9, color = FG),
    panel.grid.major = element_line(color = GRID),
    panel.grid.minor = element_blank()
  )

# Force un fond transparent + texte clair sur les sorties plotly
style_plotly <- function(p) {
  p %>% layout(
    paper_bgcolor = "rgba(0,0,0,0)",
    plot_bgcolor  = "rgba(0,0,0,0)",
    font = list(color = FG),
    legend = list(font = list(color = FG))
  )
}

# ------------------------------------------------------------------
# UI
# ------------------------------------------------------------------
ui <- page_sidebar(
  title = "League of SN",
  theme = theme_lsn,

  sidebar = sidebar(
    width = 320,
    h5("Filtres"),
    selectInput("source", "Contexte", c("Tous", "SoloQ", "Pro"), selected = "Tous"),
    selectInput("role", "Rôle", c("Tous", "TOP", "JUNGLE", "MIDDLE", "BOTTOM", "SUPPORT"), selected = "Tous"),
    selectInput("metric", "Métrique principale", metric_choices, selected = "kda"),
    sliderInput("min_games", "Minimum d'apparitions champion", min = 5, max = 100, value = 20, step = 5)
  ),

  navset_card_tab(
    # ---- Accueil ----
    nav_panel(
      "Accueil",
      layout_columns(
        value_box("Lignes SoloQ", textOutput("n_soloq"), showcase = bsicons::bs_icon("controller")),
        value_box("Lignes Pro", textOutput("n_pro"), showcase = bsicons::bs_icon("trophy")),
        value_box("Champions", textOutput("n_champions"), showcase = bsicons::bs_icon("stars")),
        value_box("Durée moy. (SoloQ / Pro)", textOutput("dur_box"), showcase = bsicons::bs_icon("clock"))
      ),
      card(
        card_header("Problématique"),
        p("Qu'est-ce qui fait gagner — la performance individuelle, ou la coordination collective ?"),
        p("Cette application confronte deux mondes : la ", strong("SoloQ"),
          " (Riot API, jeu individuel non coordonné) et la ", strong("scène Pro"),
          " (Oracle's Elixir, jeu d'équipe stratégique)."),
        p(em("Code couleur : "), span("SoloQ", style = paste0("color:", COL_SOLOQ, ";font-weight:600")),
          " / ", span("Pro", style = paste0("color:", COL_PRO, ";font-weight:600")), ".")
      ),
      card(
        card_header("Aperçu des données filtrées"),
        DTOutput("preview")
      )
    ),

    # ---- SoloQ vs Pro (cœur de l'analyse) ----
    nav_panel(
      "SoloQ vs Pro",
      card(
        card_header(textOutput("explorer_title")),
        plotlyOutput("role_metric_bar", height = "430px")
      ),
      layout_columns(
        card(card_header(textOutput("dist_title")), plotlyOutput("context_distribution", height = "360px")),
        card(card_header(textOutput("gap_title")), plotlyOutput("pro_soloq_gap", height = "360px"))
      ),
      card(
        card_header("Synthèse moyenne par contexte"),
        DTOutput("context_summary")
      )
    ),

    # ---- Profil gagnant (intègre l'analyse de Fadi) ----
    nav_panel(
      "Profil gagnant",
      card(
        card_header("Qu'est-ce qui sépare la victoire de la défaite ?"),
        p("Écart standardisé entre vainqueurs et vaincus pour chaque métrique, comparé entre les deux contextes. ",
          "Une barre positive = métrique plus élevée chez les vainqueurs. ",
          "La standardisation par contexte permet de comparer SoloQ et Pro malgré leurs échelles différentes.",
          style = paste0("color:", MUTED)),
        plotlyOutput("winner_delta", height = "500px")
      ),
      card(
        card_header("Écart vainqueurs − vaincus par rôle"),
        plotlyOutput("winrate_role", height = "340px")
      )
    ),

    # ---- Early game & objectifs (Pro only) : intègre la viz de Nezar ----
    nav_panel(
      "Early game & objectifs",
      p("Dimensions propres à la scène Pro, absentes du SoloQ (filtre Rôle actif).",
        style = paste0("color:", MUTED, ";margin-bottom:8px")),
      card(
        card_header("Taux de victoire selon l'écart de gold à 10 min"),
        plotlyOutput("gold10_winrate", height = "380px")
      ),
      layout_columns(
        card(card_header("Écart de gold à 10 min par rôle"), plotlyOutput("gold10_role", height = "380px")),
        card(card_header("Taux de victoire selon les objectifs"), plotlyOutput("objectives_winrate", height = "380px"))
      )
    ),

    # ---- Rôles ----
    nav_panel(
      "Rôles",
      card(
        card_header("Signature statistique des rôles"),
        plotlyOutput("role_heatmap", height = "500px")
      ),
      card(
        card_header("Profil de combat moyen"),
        plotlyOutput("combat_profile", height = "400px")
      )
    ),

    # ---- Champions ----
    nav_panel(
      "Champions",
      card(
        card_header(textOutput("champion_title")),
        plotlyOutput("champion_ranking", height = "500px")
      ),
      card(
        card_header("Table champions"),
        DTOutput("champion_table")
      )
    )
  )
)

# ------------------------------------------------------------------
# Server
# ------------------------------------------------------------------
server <- function(input, output, session) {

  filtered <- reactive({
    out <- df
    if (input$source != "Tous") out <- out %>% filter(source == input$source)
    if (input$role != "Tous")   out <- out %>% filter(role == input$role)
    out
  })

  # data filtrée + colonne mval = métrique sélectionnée
  scaled <- reactive({
    d <- filtered()
    d$mval <- d[[input$metric]]
    d
  })

  mlab <- reactive(metric_label(input$metric))

  # ---- value boxes ----
  output$n_soloq <- renderText(format(nrow(ranked), big.mark = " "))
  output$n_pro   <- renderText(format(nrow(pro), big.mark = " "))
  output$n_champions <- renderText(n_distinct(df$champion))
  output$dur_box <- renderText({
    d <- df %>% group_by(source) %>% summarise(m = round(mean(minutes, na.rm = TRUE)), .groups = "drop")
    paste0(d$m[d$source == "SoloQ"], " / ", d$m[d$source == "Pro"], " min")
  })

  output$preview <- renderDT({
    filtered() %>%
      select(source, role, champion, resultat, kills, deaths, assists, kda, gold, cs, damage, vision_score, wards) %>%
      head(50)
  }, options = list(pageLength = 8, scrollX = TRUE))

  # ================= SoloQ vs Pro =================
  output$explorer_title <- renderText(paste("Moyenne de", mlab(), "par rôle et par contexte"))

  output$role_metric_bar <- renderPlotly({
    p <- scaled() %>%
      filter(!is.na(mval)) %>%
      group_by(role, source) %>%
      summarise(value = mean(mval, na.rm = TRUE), n = n(), .groups = "drop") %>%
      ggplot(aes(x = role, y = value, fill = source,
                 text = paste0("Rôle : ", role,
                               "<br>Contexte : ", source,
                               "<br>Moyenne : ", round(value, 2),
                               "<br>N : ", n))) +
      geom_col(position = position_dodge(width = 0.7), width = 0.6) +
      scale_fill_manual(values = c("SoloQ" = COL_SOLOQ, "Pro" = COL_PRO)) +
      labs(title = paste("Moyenne de", mlab(), "par rôle"),
           subtitle = "Comparaison directe selon le contexte",
           x = "Rôle", y = mlab(), fill = "Contexte") +
      plot_theme
    style_plotly(ggplotly(p, tooltip = "text"))
  })

  output$dist_title <- renderText(paste("Distribution de", mlab()))

  output$context_distribution <- renderPlotly({
    p <- scaled() %>%
      filter(!is.na(mval)) %>%
      ggplot(aes(x = source, y = mval, fill = source,
                 text = paste0("Contexte : ", source, "<br>", mlab(), " : ", round(mval, 2)))) +
      geom_boxplot(outlier.alpha = 0.08, width = 0.5) +
      scale_fill_manual(values = c("SoloQ" = COL_SOLOQ, "Pro" = COL_PRO)) +
      labs(title = NULL, x = "Contexte", y = mlab()) +
      plot_theme + theme(legend.position = "none")
    style_plotly(ggplotly(p, tooltip = "text"))
  })

  output$gap_title <- renderText(paste("Écart Pro − SoloQ sur", mlab()))

  output$pro_soloq_gap <- renderPlotly({
    g <- df
    g$mval <- g[[input$metric]]

    gap <- g %>%
      filter(!is.na(mval)) %>%
      group_by(source, role) %>%
      summarise(value = mean(mval, na.rm = TRUE), .groups = "drop") %>%
      pivot_wider(names_from = source, values_from = value) %>%
      mutate(ecart = Pro - SoloQ, role = fct_reorder(role, ecart))

    p <- ggplot(gap, aes(x = role, y = ecart, fill = ecart > 0,
                         text = paste0("Rôle : ", role, "<br>Écart Pro − SoloQ : ", round(ecart, 2)))) +
      geom_col(alpha = 0.9, show.legend = FALSE) +
      geom_hline(yintercept = 0, linetype = "dashed", color = MUTED) +
      scale_fill_manual(values = c("TRUE" = COL_PRO, "FALSE" = COL_SOLOQ)) +
      coord_flip() +
      labs(title = NULL, subtitle = "Positif = plus élevé en Pro", x = "Rôle", y = "Écart Pro − SoloQ") +
      plot_theme
    style_plotly(ggplotly(p, tooltip = "text"))
  })

  output$context_summary <- renderDT({
    df %>%
      group_by(Contexte = source) %>%
      summarise(
        N = n(),
        `Durée (min)` = round(mean(minutes, na.rm = TRUE), 1),
        KDA = round(mean(kda, na.rm = TRUE), 2),
        Kills = round(mean(kills, na.rm = TRUE), 1),
        Deaths = round(mean(deaths, na.rm = TRUE), 1),
        Gold = round(mean(gold, na.rm = TRUE), 0),
        CS = round(mean(cs, na.rm = TRUE), 0),
        Vision = round(mean(vision_score, na.rm = TRUE), 1),
        Wards = round(mean(wards, na.rm = TRUE), 1),
        .groups = "drop"
      )
  }, options = list(dom = "t"))

  # ================= Profil gagnant =================
  output$winner_delta <- renderPlotly({
    d <- df %>%
      select(source, resultat, all_of(metrics_common)) %>%
      pivot_longer(all_of(metrics_common), names_to = "metric", values_to = "value") %>%
      filter(!is.na(value)) %>%
      group_by(source, metric) %>%
      mutate(z = as.numeric(scale(value))) %>%
      group_by(source, metric, resultat) %>%
      summarise(mz = mean(z, na.rm = TRUE), .groups = "drop") %>%
      pivot_wider(names_from = resultat, values_from = mz) %>%
      mutate(
        delta = Victoire - `Défaite`,
        metric = recode(metric, !!!setNames(names(metric_choices), metric_choices))
      )

    order_lvls <- d %>% group_by(metric) %>% summarise(a = mean(abs(delta))) %>% arrange(a) %>% pull(metric)
    d <- d %>% mutate(metric = factor(metric, levels = order_lvls))

    p <- ggplot(d, aes(x = metric, y = delta, fill = source,
                       text = paste0(metric, "<br>Contexte : ", source,
                                     "<br>Écart vainqueurs − vaincus : ", round(delta, 2), " σ"))) +
      geom_col(position = position_dodge(width = 0.7), width = 0.62) +
      geom_hline(yintercept = 0, linetype = "dashed", color = MUTED) +
      scale_fill_manual(values = c("SoloQ" = COL_SOLOQ, "Pro" = COL_PRO)) +
      coord_flip() +
      labs(title = NULL, subtitle = "Écart standardisé (σ) — barre positive = plus élevé chez les vainqueurs",
           x = NULL, y = "Écart vainqueurs − vaincus (σ)", fill = "Contexte") +
      plot_theme
    style_plotly(ggplotly(p, tooltip = "text"))
  })

  output$winrate_role <- renderPlotly({
    m <- input$metric
    g <- df
    g$mval <- g[[m]]

    d <- g %>%
      filter(!is.na(mval)) %>%
      group_by(role, source, resultat) %>%
      summarise(moy = mean(mval, na.rm = TRUE), .groups = "drop") %>%
      pivot_wider(names_from = resultat, values_from = moy) %>%
      mutate(ecart = Victoire - `Défaite`)

    p <- ggplot(d, aes(x = role, y = ecart, fill = source,
                       text = paste0("Rôle : ", role, "<br>Contexte : ", source,
                                     "<br>Écart vainqueurs − vaincus : ", round(ecart, 2)))) +
      geom_col(position = position_dodge(width = 0.7), width = 0.6) +
      geom_hline(yintercept = 0, linetype = "dashed", color = MUTED) +
      scale_fill_manual(values = c("SoloQ" = COL_SOLOQ, "Pro" = COL_PRO)) +
      labs(title = NULL,
           subtitle = paste0("Différence de ", mlab(), " entre vainqueurs et vaincus, par rôle"),
           x = "Rôle", y = paste("Écart sur", mlab()), fill = "Contexte") +
      plot_theme
    style_plotly(ggplotly(p, tooltip = "text"))
  })

  # ================= Early game & objectifs (Pro) =================
  pro_role <- reactive({
    if (input$role != "Tous") pro %>% filter(role == input$role) else pro
  })

  output$gold10_winrate <- renderPlotly({
    bins <- pro_role() %>%
      filter(!is.na(golddiffat10)) %>%
      mutate(tranche = cut(
        golddiffat10,
        breaks = c(-Inf, -2500, -2000, -1500, -1000, -500, 0, 500, 1000, 1500, 2000, 2500, Inf),
        labels = c("≤ -2500", "-2500/-2000", "-2000/-1500", "-1500/-1000", "-1000/-500", "-500/0",
                   "0/500", "500/1000", "1000/1500", "1500/2000", "2000/2500", "≥ 2500"),
        include.lowest = TRUE, right = TRUE)) %>%
      group_by(tranche) %>%
      summarise(winrate = mean(win, na.rm = TRUE), n = n(), .groups = "drop")

    p <- ggplot(bins, aes(x = tranche, y = winrate,
                          text = paste0("Tranche : ", tranche,
                                        "<br>Winrate : ", percent(winrate, accuracy = 1), "<br>N : ", n))) +
      geom_col(fill = COL_PRO, alpha = 0.9) +
      geom_hline(yintercept = 0.5, linetype = "dashed", color = MUTED) +
      scale_y_continuous(labels = percent_format(accuracy = 1), limits = c(0, 1)) +
      labs(title = NULL, subtitle = "Chaque barre = une tranche de 500 gold d'écart avec l'adversaire direct",
           x = "Écart de gold à 10 min", y = "Taux de victoire") +
      plot_theme + theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8))
    style_plotly(ggplotly(p, tooltip = "text"))
  })

  output$gold10_role <- renderPlotly({
    p <- pro %>%
      filter(!is.na(golddiffat10)) %>%
      ggplot(aes(x = role, y = golddiffat10, fill = resultat,
                 text = paste0("Rôle : ", role, "<br>", resultat))) +
      geom_boxplot(outlier.alpha = 0.04, width = 0.6) +
      geom_hline(yintercept = 0, linetype = "dashed", color = MUTED) +
      scale_fill_manual(values = c("Défaite" = COL_LOSE, "Victoire" = COL_WIN)) +
      coord_cartesian(ylim = c(-2500, 2500)) +
      labs(title = NULL, x = "Rôle", y = "Écart de gold à 10 min", fill = "Issue") +
      plot_theme
    style_plotly(ggplotly(p, tooltip = "text"))
  })

  output$objectives_winrate <- renderPlotly({
    drag <- pro %>% filter(!is.na(dragons)) %>%
      group_by(n = dragons) %>% summarise(winrate = mean(win), .groups = "drop") %>%
      mutate(objectif = "Dragons")
    bar <- pro %>% filter(!is.na(barons)) %>%
      group_by(n = barons) %>% summarise(winrate = mean(win), .groups = "drop") %>%
      mutate(objectif = "Barons")
    obj <- bind_rows(drag, bar)

    p <- ggplot(obj, aes(x = factor(n), y = winrate, fill = objectif,
                         text = paste0(objectif, " : ", n, "<br>Winrate : ", percent(winrate, accuracy = 1)))) +
      geom_col(position = position_dodge(width = 0.7), width = 0.6) +
      geom_hline(yintercept = 0.5, linetype = "dashed", color = MUTED) +
      scale_fill_manual(values = c("Dragons" = "#5BC0BE", "Barons" = "#E9A23B")) +
      scale_y_continuous(labels = percent_format(accuracy = 1), limits = c(0, 1)) +
      labs(title = NULL, subtitle = "Taux de victoire selon le nombre pris par l'équipe",
           x = "Nombre d'objectifs", y = "Taux de victoire", fill = NULL) +
      plot_theme
    style_plotly(ggplotly(p, tooltip = "text"))
  })

  # ================= Rôles =================
  output$role_heatmap <- renderPlotly({
    profile <- filtered() %>%
      group_by(role) %>%
      summarise(
        KDA = mean(kda, na.rm = TRUE), Kills = mean(kills, na.rm = TRUE),
        Deaths = mean(deaths, na.rm = TRUE), Assists = mean(assists, na.rm = TRUE),
        Gold = mean(gold, na.rm = TRUE), CS = mean(cs, na.rm = TRUE),
        Damage = mean(damage, na.rm = TRUE), Vision = mean(vision_score, na.rm = TRUE),
        Wards = mean(wards, na.rm = TRUE), .groups = "drop"
      ) %>%
      pivot_longer(-role, names_to = "metric", values_to = "value") %>%
      group_by(metric) %>%
      mutate(score = as.numeric(scale(value))) %>%
      ungroup()

    p <- ggplot(profile, aes(x = metric, y = role, fill = score,
                             text = paste0("Rôle : ", role, "<br>Métrique : ", metric,
                                           "<br>Score : ", round(score, 2)))) +
      geom_tile(color = "#0A1428", linewidth = 0.8) +
      scale_fill_gradient2(low = "#E9A23B", mid = "#0A1428", high = "#5BC0BE", midpoint = 0) +
      labs(title = NULL, subtitle = "Scores standardisés : teal = au-dessus de la moyenne, ambre = en dessous",
           x = "Métrique", y = "Rôle", fill = "Score") +
      plot_theme + theme(axis.text.x = element_text(angle = 25, hjust = 1))
    style_plotly(ggplotly(p, tooltip = "text"))
  })

  output$combat_profile <- renderPlotly({
    p <- filtered() %>%
      group_by(role) %>%
      summarise(Kills = mean(kills, na.rm = TRUE), Deaths = mean(deaths, na.rm = TRUE),
                Assists = mean(assists, na.rm = TRUE), .groups = "drop") %>%
      pivot_longer(-role, names_to = "stat", values_to = "value") %>%
      ggplot(aes(x = role, y = value, fill = stat,
                 text = paste0("Rôle : ", role, "<br>", stat, " : ", round(value, 2)))) +
      geom_col(position = position_dodge(width = 0.7), width = 0.62) +
      scale_fill_manual(values = c("Kills" = "#F2A65A", "Deaths" = "#8D99AE", "Assists" = "#5BC0BE")) +
      labs(title = NULL, x = "Rôle", y = "Moyenne", fill = NULL) +
      plot_theme
    style_plotly(ggplotly(p, tooltip = "text"))
  })

  # ================= Champions =================
  champion_stats <- reactive({
    d <- scaled()
    d %>%
      filter(!is.na(champion), !is.na(mval)) %>%
      group_by(champion) %>%
      summarise(apparitions = n(), winrate = mean(win, na.rm = TRUE),
                metric_mean = mean(mval, na.rm = TRUE), kda_mean = mean(kda, na.rm = TRUE),
                .groups = "drop") %>%
      filter(apparitions >= input$min_games)
  })

  output$champion_title <- renderText(paste("Top champions selon", mlab()))

  output$champion_ranking <- renderPlotly({
    p <- champion_stats() %>%
      arrange(desc(metric_mean)) %>% slice_head(n = 20) %>%
      mutate(champion = fct_reorder(champion, metric_mean)) %>%
      ggplot(aes(x = champion, y = metric_mean,
                 text = paste0("Champion : ", champion, "<br>Moyenne : ", round(metric_mean, 2),
                               "<br>Winrate : ", percent(winrate, accuracy = 1),
                               "<br>Apparitions : ", apparitions))) +
      geom_col(fill = COL_PRO, alpha = 0.9) +
      coord_flip() +
      labs(title = NULL, subtitle = paste("Minimum", input$min_games, "apparitions"),
           x = "Champion", y = mlab()) +
      plot_theme
    style_plotly(ggplotly(p, tooltip = "text"))
  })

  output$champion_table <- renderDT({
    champion_stats() %>%
      arrange(desc(metric_mean)) %>%
      mutate(winrate = percent(winrate, accuracy = 0.1),
             metric_mean = round(metric_mean, 2), kda_mean = round(kda_mean, 2))
  }, options = list(pageLength = 12))
}

shinyApp(ui, server)
