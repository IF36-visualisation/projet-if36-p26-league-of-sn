library(shiny)
library(tidyverse)
library(scales)
library(DT)
library(plotly)
library(bslib)

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
    vision_score = vision
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
    vision_score = vision
  )

df <- bind_rows(
  pro %>% select(source, role, champion, resultat, win, kills, deaths, assists, kda, gold, cs, damage, vision_score, wards),
  ranked %>% select(source, role, champion, resultat, win, kills, deaths, assists, kda, gold, cs, damage, vision_score, wards)
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

metric_label <- function(x) {
  names(metric_choices)[match(x, metric_choices)]
}

theme_lsn <- bs_theme(
  version = 5,
  bootswatch = "flatly",
  primary = "#1F6FEB",
  base_font = font_google("Inter"),
  heading_font = font_google("Inter")
)

plot_theme <- theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(size = 11, color = "gray35"),
    axis.title = element_text(size = 11),
    axis.text = element_text(size = 10),
    legend.title = element_text(size = 10),
    legend.text = element_text(size = 9),
    panel.grid.minor = element_blank()
  )

ui <- page_sidebar(
  title = "League of SN",
  theme = theme_lsn,
  
  sidebar = sidebar(
    width = 310,
    h5("Filtres"),
    selectInput("source", "Contexte", c("Tous", "SoloQ", "Pro"), selected = "Tous"),
    selectInput("role", "Rôle", c("Tous", "TOP", "JUNGLE", "MIDDLE", "BOTTOM", "SUPPORT"), selected = "Tous"),
    selectInput("metric", "Métrique principale", metric_choices, selected = "kda"),
    sliderInput("min_games", "Minimum d'apparitions champion", min = 5, max = 100, value = 20, step = 5),
    hr(),
    helpText("Les filtres s'appliquent aux onglets Explorer, Rôles et Champions.")
  ),
  
  navset_card_tab(
    nav_panel(
      "Accueil",
      layout_columns(
        value_box("Lignes SoloQ", textOutput("n_soloq"), showcase = bsicons::bs_icon("controller")),
        value_box("Lignes Pro", textOutput("n_pro"), showcase = bsicons::bs_icon("trophy")),
        value_box("Champions", textOutput("n_champions"), showcase = bsicons::bs_icon("stars")),
        value_box("Métriques", "9", showcase = bsicons::bs_icon("bar-chart"))
      ),
      card(
        card_header("Objectif"),
        p("Cette application permet d'explorer les différences de performance entre la SoloQ et la scène professionnelle sur League of Legends."),
        p("Elle met l'accent sur les rôles, les champions et les indicateurs de performance plutôt que sur des graphiques statiques du rapport.")
      ),
      card(
        card_header("Aperçu des données filtrées"),
        DTOutput("preview")
      )
    ),
    
    nav_panel(
      "Explorer",
      card(
        card_header(textOutput("explorer_title")),
        plotlyOutput("role_metric_bar", height = "460px")
      ),
      layout_columns(
        card(card_header("Résumé par rôle"), DTOutput("role_summary")),
        card(card_header("Distribution par contexte"), plotlyOutput("context_distribution", height = "360px"))
      )
    ),
    
    nav_panel(
      "SoloQ vs Pro",
      card(
        card_header(textOutput("gap_title")),
        plotlyOutput("pro_soloq_gap", height = "480px")
      ),
      card(
        card_header("Synthèse moyenne SoloQ / Pro"),
        DTOutput("context_summary")
      )
    ),
    
    nav_panel(
      "Rôles",
      card(
        card_header("Heatmap des signatures de rôles"),
        plotlyOutput("role_heatmap", height = "520px")
      ),
      card(
        card_header("Profil de combat"),
        plotlyOutput("combat_profile", height = "430px")
      )
    ),
    
    nav_panel(
      "Champions",
      card(
        card_header(textOutput("champion_title")),
        plotlyOutput("champion_ranking", height = "520px")
      ),
      card(
        card_header("Table champions"),
        DTOutput("champion_table")
      )
    )
  )
)

server <- function(input, output, session) {
  
  filtered <- reactive({
    out <- df
    
    if (input$source != "Tous") {
      out <- out %>% filter(source == input$source)
    }
    
    if (input$role != "Tous") {
      out <- out %>% filter(role == input$role)
    }
    
    out
  })
  
  output$n_soloq <- renderText(nrow(ranked))
  output$n_pro <- renderText(nrow(pro))
  output$n_champions <- renderText(n_distinct(df$champion))
  
  output$preview <- renderDT({
    filtered() %>%
      select(source, role, champion, resultat, kills, deaths, assists, kda, gold, cs, damage, vision_score, wards) %>%
      head(50)
  }, options = list(pageLength = 8, scrollX = TRUE))
  
  output$explorer_title <- renderText({
    paste("Moyenne de", metric_label(input$metric), "par rôle")
  })
  
  output$role_metric_bar <- renderPlotly({
    p <- filtered() %>%
      filter(!is.na(.data[[input$metric]])) %>%
      group_by(role, source) %>%
      summarise(
        value = mean(.data[[input$metric]], na.rm = TRUE),
        n = n(),
        .groups = "drop"
      ) %>%
      ggplot(aes(x = role, y = value, fill = source,
                 text = paste0("Rôle : ", role,
                               "<br>Contexte : ", source,
                               "<br>Moyenne : ", round(value, 2),
                               "<br>N : ", n))) +
      geom_col(position = position_dodge(width = 0.7), width = 0.6) +
      labs(
        title = paste("Moyenne de", metric_label(input$metric), "par rôle"),
        subtitle = "Comparaison directe selon le contexte",
        x = "Rôle",
        y = paste("Moyenne de", metric_label(input$metric)),
        fill = "Contexte"
      ) +
      plot_theme
    
    ggplotly(p, tooltip = "text")
  })
  
  output$role_summary <- renderDT({
    filtered() %>%
      group_by(role, source) %>%
      summarise(
        n = n(),
        moyenne = round(mean(.data[[input$metric]], na.rm = TRUE), 2),
        mediane = round(median(.data[[input$metric]], na.rm = TRUE), 2),
        q1 = round(quantile(.data[[input$metric]], 0.25, na.rm = TRUE), 2),
        q3 = round(quantile(.data[[input$metric]], 0.75, na.rm = TRUE), 2),
        .groups = "drop"
      )
  }, options = list(pageLength = 10))
  
  output$context_distribution <- renderPlotly({
    p <- filtered() %>%
      filter(!is.na(.data[[input$metric]])) %>%
      ggplot(aes(x = source, y = .data[[input$metric]], fill = source,
                 text = paste0("Contexte : ", source,
                               "<br>", metric_label(input$metric), " : ", round(.data[[input$metric]], 2)))) +
      geom_boxplot(outlier.alpha = 0.08, width = 0.5) +
      labs(
        title = paste("Distribution de", metric_label(input$metric)),
        x = "Contexte",
        y = metric_label(input$metric),
        fill = "Contexte"
      ) +
      plot_theme +
      theme(legend.position = "none")
    
    ggplotly(p, tooltip = "text")
  })
  
  output$gap_title <- renderText({
    paste("Écart Pro - SoloQ sur", metric_label(input$metric))
  })
  
  output$pro_soloq_gap <- renderPlotly({
    gap <- df %>%
      filter(!is.na(.data[[input$metric]])) %>%
      group_by(source, role) %>%
      summarise(value = mean(.data[[input$metric]], na.rm = TRUE), .groups = "drop") %>%
      pivot_wider(names_from = source, values_from = value) %>%
      mutate(
        ecart = Pro - SoloQ,
        role = fct_reorder(role, ecart)
      )
    
    p <- ggplot(gap, aes(x = role, y = ecart,
                         text = paste0("Rôle : ", role,
                                       "<br>Écart Pro - SoloQ : ", round(ecart, 2)))) +
      geom_col(fill = "#2C7BE5", alpha = 0.85) +
      geom_hline(yintercept = 0, linetype = "dashed") +
      coord_flip() +
      labs(
        title = paste("Écart moyen Pro - SoloQ sur", metric_label(input$metric)),
        subtitle = "Valeur positive : métrique plus élevée en pro",
        x = "Rôle",
        y = "Écart Pro - SoloQ"
      ) +
      plot_theme
    
    ggplotly(p, tooltip = "text")
  })
  
  output$context_summary <- renderDT({
    df %>%
      group_by(source) %>%
      summarise(
        n = n(),
        KDA = round(mean(kda, na.rm = TRUE), 2),
        Kills = round(mean(kills, na.rm = TRUE), 2),
        Deaths = round(mean(deaths, na.rm = TRUE), 2),
        Assists = round(mean(assists, na.rm = TRUE), 2),
        Gold = round(mean(gold, na.rm = TRUE), 1),
        CS = round(mean(cs, na.rm = TRUE), 1),
        Damage = round(mean(damage, na.rm = TRUE), 1),
        Vision = round(mean(vision_score, na.rm = TRUE), 1),
        Wards = round(mean(wards, na.rm = TRUE), 1),
        .groups = "drop"
      )
  }, options = list(pageLength = 5))
  
  output$role_heatmap <- renderPlotly({
    profile <- filtered() %>%
      group_by(role) %>%
      summarise(
        KDA = mean(kda, na.rm = TRUE),
        Kills = mean(kills, na.rm = TRUE),
        Deaths = mean(deaths, na.rm = TRUE),
        Assists = mean(assists, na.rm = TRUE),
        Gold = mean(gold, na.rm = TRUE),
        CS = mean(cs, na.rm = TRUE),
        Damage = mean(damage, na.rm = TRUE),
        Vision = mean(vision_score, na.rm = TRUE),
        Wards = mean(wards, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      pivot_longer(-role, names_to = "metric", values_to = "value") %>%
      group_by(metric) %>%
      mutate(score = as.numeric(scale(value))) %>%
      ungroup()
    
    p <- ggplot(profile, aes(x = metric, y = role, fill = score,
                             text = paste0("Rôle : ", role,
                                           "<br>Métrique : ", metric,
                                           "<br>Score standardisé : ", round(score, 2)))) +
      geom_tile(color = "white", linewidth = 0.8) +
      scale_fill_gradient2(low = "#D1495B", mid = "white", high = "#2C7BE5", midpoint = 0) +
      labs(
        title = "Signature statistique des rôles",
        subtitle = "Scores standardisés : bleu = au-dessus de la moyenne, rouge = en dessous",
        x = "Métrique",
        y = "Rôle",
        fill = "Score"
      ) +
      plot_theme +
      theme(axis.text.x = element_text(angle = 25, hjust = 1))
    
    ggplotly(p, tooltip = "text")
  })
  
  output$combat_profile <- renderPlotly({
    p <- filtered() %>%
      group_by(role) %>%
      summarise(
        Kills = mean(kills, na.rm = TRUE),
        Deaths = mean(deaths, na.rm = TRUE),
        Assists = mean(assists, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      pivot_longer(-role, names_to = "stat", values_to = "value") %>%
      ggplot(aes(x = role, y = value, fill = stat,
                 text = paste0("Rôle : ", role,
                               "<br>Statistique : ", stat,
                               "<br>Moyenne : ", round(value, 2)))) +
      geom_col(position = position_dodge(width = 0.7), width = 0.62) +
      labs(
        title = "Profil de combat moyen selon le rôle",
        subtitle = "Kills, deaths et assists moyens",
        x = "Rôle",
        y = "Moyenne",
        fill = "Statistique"
      ) +
      plot_theme
    
    ggplotly(p, tooltip = "text")
  })
  
  champion_stats <- reactive({
    filtered() %>%
      filter(!is.na(champion), !is.na(.data[[input$metric]])) %>%
      group_by(champion) %>%
      summarise(
        apparitions = n(),
        winrate = mean(win, na.rm = TRUE),
        metric_mean = mean(.data[[input$metric]], na.rm = TRUE),
        kda_mean = mean(kda, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      filter(apparitions >= input$min_games)
  })
  
  output$champion_title <- renderText({
    paste("Classement des champions par", metric_label(input$metric))
  })
  
  output$champion_ranking <- renderPlotly({
    p <- champion_stats() %>%
      arrange(desc(metric_mean)) %>%
      slice_head(n = 20) %>%
      mutate(champion = fct_reorder(champion, metric_mean)) %>%
      ggplot(aes(x = champion, y = metric_mean,
                 text = paste0("Champion : ", champion,
                               "<br>Moyenne : ", round(metric_mean, 2),
                               "<br>Winrate : ", percent(winrate, accuracy = 1),
                               "<br>Apparitions : ", apparitions))) +
      geom_col(fill = "#6C5B7B", alpha = 0.85) +
      coord_flip() +
      labs(
        title = paste("Top champions selon", metric_label(input$metric)),
        subtitle = paste("Minimum", input$min_games, "apparitions"),
        x = "Champion",
        y = paste("Moyenne de", metric_label(input$metric))
      ) +
      plot_theme
    
    ggplotly(p, tooltip = "text")
  })
  
  output$champion_table <- renderDT({
    champion_stats() %>%
      arrange(desc(metric_mean)) %>%
      mutate(
        winrate = percent(winrate, accuracy = 0.1),
        metric_mean = round(metric_mean, 2),
        kda_mean = round(kda_mean, 2)
      )
  }, options = list(pageLength = 12))
}

shinyApp(ui, server)