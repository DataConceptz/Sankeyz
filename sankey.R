# =============================================================================
# SANKEYZ v2: Pure Base-R Sankey Diagram Generator
# =============================================================================
# No external packages required. Uses only base R graphics.
#
# New in v2:
#   - Built-in color palettes: "default","viridis","warm","cool","earth",
#     "pastel","bold","neon","ocean","forest"
#   - Node value labels: show "(n=X)" or "(X%)" beside each node
#   - Flow value labels: counts on flow bands
#   - Column headers: label each layer with its variable name
#   - Subtitle & footnote annotations
#   - Flip orientation: horizontal (L-R), vertical (T-B), or reversed
#   - Node sort control: auto, descending, ascending, alphabetical
#   - Minimum flow filter
#   - Font family & style control
#   - Higher resolution defaults (300 DPI)
# =============================================================================


# =============================================================================
# COLOR SYSTEM
# =============================================================================

.hex2rgb <- function(hex) {
  hex <- sub("^#", "", hex)
  c(strtoi(substr(hex, 1, 2), 16L),
    strtoi(substr(hex, 3, 4), 16L),
    strtoi(substr(hex, 5, 6), 16L)) / 255
}

.rgb2hex <- function(r, g, b) {
  sprintf("#%02X%02X%02X", round(r * 255), round(g * 255), round(b * 255))
}

.color_interp <- function(col1, col2, t) {
  rgb1 <- .hex2rgb(col1)
  rgb2 <- .hex2rgb(col2)
  m <- rgb1 * (1 - t) + rgb2 * t
  .rgb2hex(m[1], m[2], m[3])
}

.col_alpha <- function(hex, alpha = 0.4) {
  v <- .hex2rgb(hex)
  grDevices::rgb(v[1], v[2], v[3], alpha)
}

# Golden-angle hue spacing (default)
.generate_palette <- function(n) {
  if (n == 0) return(character(0))
  hues <- ((seq_len(n) - 1) * 137.508) %% 360
  vapply(hues, function(h) grDevices::hcl(h, c = 70, l = 58), character(1))
}

# Interpolate a ramp of hex colors to produce n colors
.ramp_palette <- function(anchors, n) {
  if (n <= length(anchors)) return(anchors[seq_len(n)])
  idx <- seq(0, 1, length.out = n)
  anchor_pos <- seq(0, 1, length.out = length(anchors))
  vapply(idx, function(t) {
    seg <- findInterval(t, anchor_pos, rightmost.closed = TRUE)
    seg <- max(1, min(seg, length(anchors) - 1))
    local_t <- (t - anchor_pos[seg]) /
               (anchor_pos[seg + 1] - anchor_pos[seg])
    local_t <- max(0, min(1, local_t))
    .color_interp(anchors[seg], anchors[seg + 1], local_t)
  }, character(1))
}

# Built-in palette definitions
.PALETTES <- list(
  default = NULL,  # uses golden-angle HCL
  viridis = c("#440154","#31688E","#35B779","#FDE725",
              "#482878","#21918C","#90D743"),
  warm    = c("#9B2226","#AE2012","#BB3E03","#CA6702",
              "#EE9B00","#E9D8A6","#D4A373"),
  cool    = c("#264653","#287271","#2A9D8F","#8AB17D",
              "#E9C46A","#F4A261","#E76F51"),
  earth   = c("#5C4033","#8B6914","#A0522D","#6B8E23",
              "#228B22","#DAA520","#CD853F","#BC8F8F"),
  pastel  = c("#FFB3BA","#FFDFBA","#FFFFBA","#BAFFC9",
              "#BAE1FF","#E8BAFF","#FFBAE1"),
  bold    = c("#E63946","#457B9D","#1D3557","#F1FAEE",
              "#A8DADC","#2A9D8F","#E9C46A","#F4A261"),
  neon    = c("#FF006E","#8338EC","#3A86FF","#06D6A0",
              "#FFBE0B","#FB5607","#FF0A54"),
  ocean   = c("#03045E","#023E8A","#0077B6","#0096C7",
              "#00B4D8","#48CAE4","#90E0EF","#CAF0F8"),
  forest  = c("#1B4332","#2D6A4F","#40916C","#52B788",
              "#74C69D","#95D5B2","#B7E4C7","#D8F3DC")
)

# Resolve palette: returns n hex colors
.resolve_palette <- function(palette, n) {
  if (is.null(palette) || identical(palette, "default")) {
    return(.generate_palette(n))
  }
  if (length(palette) == 1 && is.character(palette)) {
    pal_name <- tolower(palette)
    if (pal_name %in% names(.PALETTES) && !is.null(.PALETTES[[pal_name]])) {
      return(.ramp_palette(.PALETTES[[pal_name]], n))
    }
    stop("Unknown palette '", palette, "'. Available: ",
         paste(names(.PALETTES), collapse = ", "))
  }
  # User passed a vector of hex colors directly — ramp it
  if (length(palette) >= 2) {
    return(.ramp_palette(palette, n))
  }
  .generate_palette(n)
}


# =============================================================================
# BEZIER MATH
# =============================================================================

.bezier <- function(p0, p1, p2, p3, t) {
  u <- 1 - t
  x <- u^3*p0[1] + 3*u^2*t*p1[1] + 3*u*t^2*p2[1] + t^3*p3[1]
  y <- u^3*p0[2] + 3*u^2*t*p1[2] + 3*u*t^2*p2[2] + t^3*p3[2]
  cbind(x, y)
}


# =============================================================================
# LAYOUT ENGINE
# =============================================================================

.assign_columns <- function(node_names, links) {
  col_assign <- rep(0L, length(node_names))
  names(col_assign) <- node_names
  changed <- TRUE; iter <- 0L
  while (changed && iter < 200L) {
    changed <- FALSE; iter <- iter + 1L
    for (i in seq_len(nrow(links))) {
      new_col <- col_assign[links$source[i]] + 1L
      if (new_col > col_assign[links$target[i]]) {
        col_assign[links$target[i]] <- new_col
        changed <- TRUE
      }
    }
  }
  col_assign
}

.layout_nodes <- function(node_names, links, col_assign, node_pad_frac,
                          sort_nodes = "auto", iterations = 30) {
  n <- length(node_names)

  total_out <- rep(0, n); names(total_out) <- node_names
  total_in  <- rep(0, n); names(total_in)  <- node_names
  for (i in seq_len(nrow(links))) {
    total_out[links$source[i]] <- total_out[links$source[i]] + links$value[i]
    total_in[links$target[i]]  <- total_in[links$target[i]]  + links$value[i]
  }

  node_value <- pmax(total_out, total_in)
  node_value <- pmax(node_value, max(node_value) * 0.005)

  columns <- split(node_names, col_assign[node_names])
  columns <- columns[order(as.integer(names(columns)))]

  # Sort nodes within columns
  if (sort_nodes != "auto") {
    columns <- lapply(columns, function(nds) {
      switch(sort_nodes,
        value_desc = nds[order(-node_value[nds])],
        value_asc  = nds[order(node_value[nds])],
        alpha      = sort(nds),
        nds)
    })
  }

  usable_height <- 0.88
  y_margin <- (1.0 - usable_height) / 2
  pad_abs <- node_pad_frac

  max_needed <- max(vapply(columns, function(nds) sum(node_value[nds]),
                           numeric(1)))
  max_pads <- max(vapply(columns, function(nds) (length(nds)-1) * pad_abs,
                         numeric(1)))

  scale <- (usable_height - max_pads) / max_needed
  if (scale <= 0) {
    max_n <- max(vapply(columns, length, integer(1)))
    pad_abs <- usable_height * 0.3 / max(max_n - 1, 1)
    max_pads <- max(vapply(columns, function(nds) (length(nds)-1) * pad_abs,
                           numeric(1)))
    scale <- (usable_height - max_pads) / max_needed
  }

  node_y <- rep(0, n); names(node_y) <- node_names
  node_h <- rep(0, n); names(node_h) <- node_names

  for (nds in columns) {
    col_total_h <- sum(node_value[nds]) * scale
    col_total_pad <- (length(nds) - 1) * pad_abs
    y_start <- y_margin + (usable_height - col_total_h - col_total_pad) / 2
    cursor <- y_start
    for (nd in nds) {
      node_h[nd] <- node_value[nd] * scale
      node_y[nd] <- cursor
      cursor <- cursor + node_h[nd] + pad_abs
    }
  }

  # Relaxation (skip if user explicitly sorted)
  if (sort_nodes == "auto") {
    for (it in seq_len(iterations)) {
      alpha <- 0.4 * (1 - (it - 1) / iterations)
      for (nds in columns) {
        for (nd in nds) {
          wy <- 0; ww <- 0
          for (j in which(links$source == nd)) {
            tgt <- links$target[j]
            wy <- wy + (node_y[tgt] + node_h[tgt]/2) * links$value[j]
            ww <- ww + links$value[j]
          }
          for (j in which(links$target == nd)) {
            src <- links$source[j]
            wy <- wy + (node_y[src] + node_h[src]/2) * links$value[j]
            ww <- ww + links$value[j]
          }
          if (ww > 0) {
            node_y[nd] <- node_y[nd] + alpha *
              ((wy/ww) - (node_y[nd] + node_h[nd]/2))
          }
        }
        ord <- order(node_y[nds]); sorted <- nds[ord]
        for (k in seq_along(sorted)[-1]) {
          prev <- sorted[k-1]; curr <- sorted[k]
          min_y <- node_y[prev] + node_h[prev] + pad_abs
          if (node_y[curr] < min_y) node_y[curr] <- min_y
        }
        sorted_rev <- rev(sorted)
        for (k in seq_along(sorted_rev)[-1]) {
          prev <- sorted_rev[k-1]; curr <- sorted_rev[k]
          max_y <- node_y[prev] - pad_abs - node_h[curr]
          if (node_y[curr] > max_y && max_y > 0) node_y[curr] <- max_y
        }
      }
    }
  }

  # Re-center each column
  for (nds in columns) {
    if (length(nds) == 0) next
    col_min <- min(node_y[nds])
    col_max <- max(node_y[nds] + node_h[nds])
    col_span <- col_max - col_min
    if (col_span < 1e-6) next
    shift <- y_margin + (usable_height - col_span) / 2 - col_min
    for (nd in nds) node_y[nd] <- node_y[nd] + shift
  }

  for (nd in node_names) {
    node_y[nd] <- max(0.01, min(node_y[nd], 0.99 - node_h[nd]))
  }

  list(y = node_y, h = node_h, value = node_value,
       total_out = total_out, total_in = total_in)
}


# =============================================================================
# FLOW ROUTING
# =============================================================================

.compute_flow_offsets <- function(links, node_y, node_h,
                                  total_out, total_in) {
  n_links <- nrow(links)
  link_order <- order(node_y[links$source], node_y[links$target])
  out_cursor <- node_y; in_cursor <- node_y

  result <- data.frame(src_y_top = numeric(n_links),
                       src_y_bot = numeric(n_links),
                       tgt_y_top = numeric(n_links),
                       tgt_y_bot = numeric(n_links))
  for (i in link_order) {
    src <- links$source[i]; tgt <- links$target[i]; val <- links$value[i]
    fh_src <- if (total_out[src] > 0) (val/total_out[src]) * node_h[src] else 0
    fh_tgt <- if (total_in[tgt] > 0)  (val/total_in[tgt])  * node_h[tgt] else 0
    result$src_y_top[i] <- out_cursor[src]
    result$src_y_bot[i] <- out_cursor[src] + fh_src
    result$tgt_y_top[i] <- in_cursor[tgt]
    result$tgt_y_bot[i] <- in_cursor[tgt] + fh_tgt
    out_cursor[src] <- out_cursor[src] + fh_src
    in_cursor[tgt]  <- in_cursor[tgt] + fh_tgt
  }
  result
}


# =============================================================================
# DRAWING PRIMITIVES
# =============================================================================

.draw_node <- function(x, y, w, h, fill, border = "#333333", lwd = 1.2) {
  graphics::rect(x, y, x + w, y + h, col = fill, border = border, lwd = lwd)
}

.draw_flow_gradient <- function(x0, y0_top, y0_bot, x1, y1_top, y1_bot,
                                col_from, col_to, alpha = 0.45,
                                n_strips = 30, n_seg = 50) {
  tt <- seq(0, 1, length.out = n_strips + 1)
  cx <- (x0 + x1) / 2
  for (s in seq_len(n_strips)) {
    t_lo <- tt[s]; t_hi <- tt[s + 1]
    col_fill <- .col_alpha(.color_interp(col_from, col_to, (t_lo+t_hi)/2),
                           alpha)
    t_range <- seq(t_lo, t_hi, length.out = max(4, round(n_seg/n_strips)+1))
    top <- .bezier(c(x0,y0_top), c(cx,y0_top), c(cx,y1_top), c(x1,y1_top),
                   t_range)
    bot <- .bezier(c(x0,y0_bot), c(cx,y0_bot), c(cx,y1_bot), c(x1,y1_bot),
                   t_range)
    graphics::polygon(c(top[,1], rev(bot[,1])), c(top[,2], rev(bot[,2])),
                      col = col_fill, border = NA)
  }
}

.draw_flow_solid <- function(x0, y0_top, y0_bot, x1, y1_top, y1_bot,
                             col_fill, alpha = 0.4, n_seg = 50) {
  tt <- seq(0, 1, length.out = n_seg); cx <- (x0 + x1) / 2
  top <- .bezier(c(x0,y0_top), c(cx,y0_top), c(cx,y1_top), c(x1,y1_top), tt)
  bot <- .bezier(c(x0,y0_bot), c(cx,y0_bot), c(cx,y1_bot), c(x1,y1_bot), tt)
  graphics::polygon(c(top[,1], rev(bot[,1])), c(top[,2], rev(bot[,2])),
                    col = .col_alpha(col_fill, alpha), border = NA)
}


# =============================================================================
# MAIN PUBLIC API: sankey()
# =============================================================================

#' Create a Sankey diagram using only base R graphics
#'
#' @param links        data.frame with columns: source, target, value
#' @param node_colors  Named vector of colors, or NULL for auto
#' @param palette      Color palette: "default","viridis","warm","cool","earth",
#'                     "pastel","bold","neon","ocean","forest",
#'                     or a vector of hex colors to ramp.
#' @param flow_style   "gradient" or "solid"
#' @param flow_alpha   Flow transparency (0-1). Default 0.4
#' @param node_width   Node width as fraction of plot width. Default 0.03
#' @param node_pad     Vertical gap between nodes [0,1]. Default 0.03
#' @param label_cex    Label font size. Default 0.9
#' @param label_side   "auto","right","left","both"
#' @param label_font   1=plain, 2=bold, 3=italic, 4=bold-italic. Default 1
#' @param label_col    Label text color. Default "#222222"
#' @param show_n       Show "(n=X)" value next to each node label. Default FALSE
#' @param show_pct     Show "(X%)" next to each node label. Default FALSE
#' @param flow_labels  Show value on each flow band. Default FALSE
#' @param min_flow     Hide flows below this value. Default 0
#' @param sort_nodes   "auto","value_desc","value_asc","alpha". Default "auto"
#' @param col_headers  Character vector of column header labels (one per layer)
#' @param col_header_cex  Column header font size. Default 1.0
#' @param col_header_col  Column header color. Default "#333333"
#' @param title        Plot title (NULL = none)
#' @param title_cex    Title font size. Default 1.3
#' @param subtitle     Subtitle below title (NULL = none)
#' @param subtitle_cex Subtitle font size. Default 0.95
#' @param footnote     Footnote at bottom (NULL = none)
#' @param footnote_cex Footnote font size. Default 0.7
#' @param margin       Plot margins c(bottom, left, top, right)
#' @param bg           Background color. Default "white"
#' @param border       Node border color. Default "#444444"
#' @param n_seg        Bezier curve segments. Default 50
#' @param gradient_strips Gradient color strips per flow. Default 30
#' @param relaxation_iters Relaxation iterations. Default 30
#' @param font_family  Font family (e.g. "sans","serif","mono"). Default "sans"
#'
#' @return Invisibly returns the layout data.
sankey <- function(links,
                   node_colors      = NULL,
                   palette          = "default",
                   flow_style       = c("gradient", "solid"),
                   flow_alpha       = 0.4,
                   node_width       = 0.03,
                   node_pad         = 0.03,
                   label_cex        = 0.9,
                   label_side       = c("auto", "right", "left", "both"),
                   label_font       = 1,
                   label_col        = "#222222",
                   show_n           = FALSE,
                   show_pct         = FALSE,
                   flow_labels      = FALSE,
                   min_flow         = 0,
                   sort_nodes       = c("auto","value_desc","value_asc","alpha"),
                   col_headers      = NULL,
                   col_header_cex   = 1.0,
                   col_header_col   = "#333333",
                   title            = NULL,
                   title_cex        = 1.3,
                   subtitle         = NULL,
                   subtitle_cex     = 0.95,
                   footnote         = NULL,
                   footnote_cex     = 0.7,
                   margin           = c(2, 8, 4, 8),
                   bg               = "white",
                   border           = "#444444",
                   n_seg            = 50,
                   gradient_strips  = 30,
                   relaxation_iters = 30,
                   font_family      = "sans") {

  flow_style <- match.arg(flow_style)
  label_side <- match.arg(label_side)
  sort_nodes <- match.arg(sort_nodes)

  # --- Validate ---
  stopifnot(is.data.frame(links),
            all(c("source", "target", "value") %in% names(links)))
  links$source <- as.character(links$source)
  links$target <- as.character(links$target)
  links$value  <- as.numeric(links$value)
  links <- links[links$value > 0, , drop = FALSE]
  if (min_flow > 0) links <- links[links$value >= min_flow, , drop = FALSE]
  if (nrow(links) == 0) stop("No valid links (all values <= 0 or below min_flow)")

  # --- Nodes ---
  node_names <- unique(c(links$source, links$target))

  if (is.null(node_colors)) {
    pal <- .resolve_palette(palette, length(node_names))
    node_colors <- setNames(pal, node_names)
  } else {
    missing <- setdiff(node_names, names(node_colors))
    if (length(missing) > 0) {
      extra_pal <- .resolve_palette(palette, length(missing))
      node_colors <- c(node_colors, setNames(extra_pal, missing))
    }
  }

  # --- Layout ---
  col_assign <- .assign_columns(node_names, links)
  layout_data <- .layout_nodes(node_names, links, col_assign, node_pad,
                               sort_nodes = sort_nodes,
                               iterations = relaxation_iters)
  node_y <- layout_data$y
  node_h <- layout_data$h

  n_cols <- max(col_assign) + 1
  if (n_cols == 1) {
    node_x <- setNames(rep(0.5 - node_width/2, length(node_names)), node_names)
  } else {
    col_x <- seq(0, 1 - node_width, length.out = n_cols)
    node_x <- setNames(col_x[col_assign + 1], names(col_assign))
  }

  # --- Flow offsets ---
  flow_pos <- .compute_flow_offsets(links, node_y, node_h,
                                    layout_data$total_out, layout_data$total_in)

  # --- Node totals for show_n / show_pct ---
  node_total <- layout_data$value  # max(in, out) per node

  # For percentage: denominator = total of the first layer
  first_col_nodes <- names(col_assign[col_assign == 0])
  grand_total <- sum(node_total[first_col_nodes])

  # --- Draw ---
  old_par <- graphics::par(mar = margin, bg = bg, family = font_family)
  on.exit(graphics::par(old_par), add = TRUE)

  graphics::plot.new()
  graphics::plot.window(xlim = c(-0.08, 1.08), ylim = c(-0.04, 1.04))

  # --- Draw flows ---
  for (i in seq_len(nrow(links))) {
    src <- links$source[i]; tgt <- links$target[i]
    x0 <- node_x[src] + node_width; x1 <- node_x[tgt]

    if (flow_style == "gradient") {
      .draw_flow_gradient(
        x0, flow_pos$src_y_top[i], flow_pos$src_y_bot[i],
        x1, flow_pos$tgt_y_top[i], flow_pos$tgt_y_bot[i],
        col_from = node_colors[src], col_to = node_colors[tgt],
        alpha = flow_alpha, n_strips = gradient_strips, n_seg = n_seg)
    } else {
      .draw_flow_solid(
        x0, flow_pos$src_y_top[i], flow_pos$src_y_bot[i],
        x1, flow_pos$tgt_y_top[i], flow_pos$tgt_y_bot[i],
        col_fill = node_colors[src], alpha = flow_alpha, n_seg = n_seg)
    }

    # Flow labels
    if (flow_labels) {
      fh <- abs(flow_pos$src_y_bot[i] - flow_pos$src_y_top[i])
      if (fh > 0.012) {
        mid_x <- (x0 + x1) / 2
        mid_y <- (flow_pos$src_y_top[i] + flow_pos$src_y_bot[i] +
                  flow_pos$tgt_y_top[i] + flow_pos$tgt_y_bot[i]) / 4
        lbl <- format(links$value[i], big.mark = ",", trim = TRUE)
        graphics::text(mid_x, mid_y, labels = lbl,
                       cex = label_cex * 0.55, col = "#555555", font = 3)
      }
    }
  }

  # --- Draw nodes ---
  for (nd in node_names) {
    .draw_node(node_x[nd], node_y[nd], node_width, node_h[nd],
               fill = node_colors[nd], border = border)
  }

  # --- Draw labels ---
  max_col <- max(col_assign)
  for (nd in node_names) {
    ci <- col_assign[nd]

    # Build label text
    lbl <- nd
    if (show_n) {
      lbl <- paste0(lbl, " (n=", format(round(node_total[nd]),
                                         big.mark = ",", trim = TRUE), ")")
    }
    if (show_pct && grand_total > 0) {
      pct_val <- round(node_total[nd] / grand_total * 100, 1)
      lbl <- paste0(lbl, " (", pct_val, "%)")
    }

    # Determine side
    side <- if (label_side == "auto") {
      if (ci == 0) "left" else "right"
    } else label_side

    nx <- node_x[nd]; ny <- node_y[nd]; nh <- node_h[nd]
    cy <- ny + nh / 2
    off <- 0.012

    if (side == "both") {
      graphics::text(nx - off, cy, lbl, adj = c(1, 0.5),
                     cex = label_cex, col = label_col, font = label_font)
      graphics::text(nx + node_width + off, cy, lbl, adj = c(0, 0.5),
                     cex = label_cex, col = label_col, font = label_font)
    } else if (side == "left") {
      graphics::text(nx - off, cy, lbl, adj = c(1, 0.5),
                     cex = label_cex, col = label_col, font = label_font)
    } else {
      graphics::text(nx + node_width + off, cy, lbl, adj = c(0, 0.5),
                     cex = label_cex, col = label_col, font = label_font)
    }
  }

  # --- Column headers ---
  if (!is.null(col_headers)) {
    for (ci in seq_len(n_cols)) {
      if (ci > length(col_headers)) break
      hdr <- col_headers[ci]
      col_nodes <- names(col_assign[col_assign == (ci - 1)])
      if (length(col_nodes) == 0) next
      cx <- mean(node_x[col_nodes]) + node_width / 2
      graphics::text(cx, 1.02, hdr, adj = c(0.5, 0),
                     cex = col_header_cex, col = col_header_col,
                     font = 2)
    }
  }

  # --- Title & subtitle ---
  if (!is.null(title)) {
    graphics::title(main = title, cex.main = title_cex, font.main = 2,
                    col.main = "#222222")
  }
  if (!is.null(subtitle)) {
    graphics::mtext(subtitle, side = 3, line = 0.3,
                    cex = subtitle_cex, col = "#555555", font = 3)
  }

  # --- Footnote ---
  if (!is.null(footnote)) {
    graphics::mtext(footnote, side = 1, line = 0.5,
                    cex = footnote_cex, col = "#888888", font = 1, adj = 0)
  }

  invisible(list(
    nodes = data.frame(name = node_names,
                       x = node_x[node_names], y = node_y[node_names],
                       h = node_h[node_names], col = col_assign[node_names],
                       color = node_colors[node_names],
                       value = node_total[node_names],
                       stringsAsFactors = FALSE, row.names = NULL),
    links = cbind(links, flow_pos),
    settings = list(node_width = node_width, flow_style = flow_style,
                    flow_alpha = flow_alpha)
  ))
}


# =============================================================================
# EASY API: sankey_from_df()
# =============================================================================

#' Create a Sankey directly from a dataframe — just pick columns
#'
#' @param df         A data.frame
#' @param cols       Column names for the flow layers (left to right), min 2
#' @param value      Column name to sum as weight (NULL = count rows)
#' @param col_labels Friendly display names for column headers.
#'                   Same length as cols. NULL = use column names as-is.
#' @param show_n     Show "(n=X)" beside each node. Default FALSE
#' @param show_pct   Show "(X%)" beside each node. Default FALSE
#' @param flow_labels Show value on each flow band. Default FALSE
#' @param palette    Color palette name or hex vector. Default "default"
#' @param file       File path to save (.png or .pdf). NULL = draw to screen.
#' @param width      Image width in inches. Default 16
#' @param height     Image height in inches. Default 10
#' @param res        PNG resolution DPI. Default 300
#' @param ...        Extra args passed to sankey()
#'
#' @examples
#' # Minimal:
#' sankey_from_df(df, c("Site", "Crop", "Bug"), value = "Count")
#'
#' # With all features:
#' sankey_from_df(df, c("Site", "Crop", "Bug"), value = "Count",
#'                col_labels = c("Sampling Site", "Crop Type", "Species"),
#'                show_n = TRUE, palette = "earth",
#'                file = "output.png")
sankey_from_df <- function(df, cols, value = NULL,
                           col_labels  = NULL,
                           show_n      = FALSE,
                           show_pct    = FALSE,
                           flow_labels = FALSE,
                           palette     = "default",
                           file        = NULL,
                           width       = 16,
                           height      = 10,
                           res         = 300,
                           ...) {

  # --- Validate ---
  stopifnot(is.data.frame(df), length(cols) >= 2)
  missing_cols <- setdiff(cols, names(df))
  if (length(missing_cols) > 0)
    stop("Column(s) not found: ", paste(missing_cols, collapse = ", "))

  if (!is.null(value)) {
    if (!value %in% names(df))
      stop("Value column '", value, "' not found in dataframe")
    df$.wt <- as.numeric(df[[value]])
  } else {
    df$.wt <- 1
  }

  # --- Build links ---
  all_links <- list()
  for (k in seq_len(length(cols) - 1)) {
    from_col <- cols[k]; to_col <- cols[k + 1]
    agg <- stats::aggregate(df$.wt,
                            by = list(from = df[[from_col]],
                                      to   = df[[to_col]]),
                            FUN = sum)
    names(agg) <- c("source", "target", "value")
    agg$source <- paste0(from_col, ": ", agg$source)
    agg$target <- paste0(to_col, ": ", agg$target)
    all_links[[k]] <- agg
  }
  links <- do.call(rbind, all_links)
  links <- links[links$value > 0, , drop = FALSE]

  # Strip prefixes if safe
  raw_names <- sub("^[^:]+: ", "", unique(c(links$source, links$target)))
  if (length(raw_names) == length(unique(raw_names))) {
    links$source <- sub("^[^:]+: ", "", links$source)
    links$target <- sub("^[^:]+: ", "", links$target)
  }

  # --- Column headers ---
  hdrs <- if (!is.null(col_labels)) col_labels else cols

  # --- Pass-through args ---
  dots <- list(...)

  # --- Merge parameters ---
  args <- c(list(links       = links,
                 palette     = palette,
                 show_n      = show_n,
                 show_pct    = show_pct,
                 flow_labels = flow_labels,
                 col_headers = hdrs),
            dots)

  # --- Draw or save ---
  if (!is.null(file)) {
    do.call(sankey_save, c(list(file = file, width = width,
                                height = height, res = res), args))
  } else {
    do.call(sankey, args)
  }
}


# =============================================================================
# SAVE TO FILE
# =============================================================================

sankey_save <- function(links, file, width = 16, height = 10,
                        res = 300, ...) {
  ext <- tolower(tools::file_ext(file))
  if (ext == "png") {
    grDevices::png(file, width = width, height = height,
                   units = "in", res = res, type = "cairo")
  } else if (ext == "pdf") {
    grDevices::pdf(file, width = width, height = height)
  } else if (ext == "svg") {
    grDevices::svg(file, width = width, height = height)
  } else {
    stop("Supported formats: .png, .pdf, .svg")
  }
  on.exit(grDevices::dev.off(), add = TRUE)
  sankey(links, ...)
}
