run_map <- function(cfg) {
  needed <- c("sf","leaflet","htmlwidgets","ggplot2","jsonlite")
  missing <- needed[!vapply(needed,requireNamespace,logical(1),quietly=TRUE)]
  if(length(missing)) stop("Missing packages: ",paste(missing,collapse=", "))
  for(k in c("project","source","code","name","value")) if(is.null(cfg[[k]])) stop("Missing config: ",k)
  default <- function(x,y) if(is.null(x)) y else x
  root <- normalizePath(cfg$project,mustWork=TRUE)
  path <- function(p) file.path(root,p)
  for(d in c("00_admin","01_data/raw","01_data/derived","02_code","03_output")) dir.create(path(d),recursive=TRUE,showWarnings=FALSE)
  rp <- path("Project.Rproj")
  if(!file.exists(rp)) writeLines(c("Version: 1.0","RestoreWorkspace: No","SaveWorkspace: No","Encoding: UTF-8"),rp)
  stem <- default(cfg$output,"map")
  if(!grepl("^[A-Za-z0-9_-]+$",stem)) stop("output must be a simple filename stem")
  dest <- path(paste0("03_output/",stem,".html"))
  png <- path(paste0("03_output/",stem,".png"))
  derived <- path(paste0("01_data/derived/",stem,".geojson"))
  if(!isTRUE(cfg$overwrite) && any(file.exists(c(dest,png,derived)))) stop("Output exists; choose another stem")
  args <- list(dsn=path(cfg$source),quiet=TRUE)
  if(!is.null(cfg$layer)) args$layer <- cfg$layer
  x <- do.call(sf::st_read,args)
  if(is.na(sf::st_crs(x))) stop("Unknown CRS")
  if(!all(c(cfg$code,cfg$name)%in%names(x))) stop("Map fields missing")
  x$.code <- as.character(x[[cfg$code]])
  if(!is.null(cfg$codes)) x <- x[x$.code %in% cfg$codes,]
  if(!nrow(x)||anyNA(x$.code)||anyDuplicated(x$.code)) stop("Empty or duplicate map keys")
  if(!all(as.character(sf::st_geometry_type(x)) %in% c("POLYGON","MULTIPOLYGON"))) stop("Polygon map required")
  x$.name <- as.character(x[[cfg$name]])
  if(!is.null(cfg$table)) {
    d <- read.csv(path(cfg$table),colClasses="character",check.names=FALSE,fileEncoding="UTF-8-BOM")
    cols <- c(cfg$table_code,cfg$table_name,cfg$value)
    if(length(cols)!=3 || !all(cols %in% names(d))) stop("Table fields missing")
    keys <- d[[cfg$table_code]]
    if(anyNA(keys)||anyDuplicated(keys)) stop("Duplicate/missing table keys")
    if(!all(keys %in% x$.code)) stop("Table codes absent from map")
    x <- x[match(keys,x$.code),]
    if(anyNA(x$.name)||anyNA(d[[cfg$table_name]])||any(trimws(x$.name)!=trimws(d[[cfg$table_name]]))) stop("Code/name conflict")
    raw <- d[[cfg$value]]
  } else {
    if(!cfg$value %in% names(x)) stop("Value field missing")
    raw <- x[[cfg$value]]
  }
  x$.value <- suppressWarnings(as.numeric(raw))
  invalid <- !is.na(raw) & trimws(as.character(raw))!="" & is.na(x$.value)
  if(any(invalid)||any(is.infinite(x$.value))||all(is.na(x$.value))) stop("Invalid numeric values")
  x <- sf::st_transform(sf::st_make_valid(x),4326)
  if(any(sf::st_is_empty(x))) stop("Empty geometry")
  unit <- default(cfg$unit,"")
  title <- default(cfg$title,"Spatial indicator")
  pal <- leaflet::colorNumeric("YlOrRd",domain=x$.value,na.color="#bdbdbd")
  x$.fill <- pal(x$.value)
  if(!is.null(cfg$breaks)) {
    b <- as.numeric(cfg$breaks)
    if(length(b)<2||anyNA(b)||any(diff(b)<=0)||min(x$.value,na.rm=TRUE)<min(b)||max(x$.value,na.rm=TRUE)>max(b)) stop("Invalid breaks")
    labs <- cfg$labels
    if(!is.null(labs)&&length(labs)!=length(b)-1) stop("Invalid labels")
    x$.group <- cut(x$.value,b,include.lowest=TRUE,labels=labs)
    pal <- leaflet::colorFactor("YlOrRd",domain=x$.group,na.color="#bdbdbd")
    x$.fill <- pal(x$.group)
  }
  esc <- function(s) as.character(htmltools::htmlEscape(s))
  popup <- paste0("<b>",esc(x$.name),"</b><br>",esc(x$.code),"<br>",esc(as.character(x$.value))," ",esc(unit))
  m <- leaflet::leaflet(x)
  m <- leaflet::addProviderTiles(m,leaflet::providers$CartoDB.Positron)
  m <- leaflet::addPolygons(m,fillColor=x$.fill,fillOpacity=.75,color="#64748b",weight=1.2,
    label=x$.name,popup=popup,group="Indicator",highlightOptions=leaflet::highlightOptions(weight=3))
  if(is.null(cfg$breaks)) m <- leaflet::addLegend(m,pal=pal,values=x$.value,title=esc(paste(title,unit)))
  else m <- leaflet::addLegend(m,pal=pal,values=x$.group,title=esc(paste(title,unit)))
  groups <- "Indicator"
  if(!is.null(cfg$points)) {
    p <- cfg$points
    if(is.null(p$epsg)) stop("Point EPSG required")
    pts <- read.csv(path(p$source),check.names=FALSE,fileEncoding="UTF-8-BOM")
    if(!all(c(p$lon,p$lat,p$name)%in%names(pts))||!nrow(pts)) stop("Point fields missing")
    for(k in c(p$lon,p$lat)) {pts[[k]]<-suppressWarnings(as.numeric(pts[[k]]));if(any(!is.finite(pts[[k]]))) stop("Invalid point coordinates")}
    pts <- sf::st_as_sf(pts,coords=c(p$lon,p$lat),crs=p$epsg)
    pts <- sf::st_transform(pts,4326)
    xy <- sf::st_coordinates(pts)
    if(any(abs(xy[,1])>180)|any(abs(xy[,2])>90)) stop("Invalid point range")
    pc <- rep("#2166ac",nrow(pts))
    if(!is.null(p$category)) {
      if(!p$category %in% names(pts)) stop("Point category missing")
      pp <- leaflet::colorFactor("Set2",domain=pts[[p$category]])
      pc <- pp(pts[[p$category]])
      m <- leaflet::addLegend(m,pal=pp,values=pts[[p$category]],title=esc(p$category))
    }
    m <- leaflet::addCircleMarkers(m,data=pts,radius=6,color=pc,popup=esc(pts[[p$name]]),group="Points")
    groups <- c(groups,"Points")
  }
  m <- leaflet::addLayersControl(m,overlayGroups=groups)
  m <- leaflet::addScaleBar(m)
  bb <- sf::st_bbox(x)
  m <- leaflet::fitBounds(m,bb[["xmin"]],bb[["ymin"]],bb[["xmax"]],bb[["ymax"]])
  if(isTRUE(cfg$static)) {
    xp <- sf::st_transform(x,3857)
    g <- ggplot2::ggplot(xp)+ggplot2::geom_sf(ggplot2::aes(fill=.fill),color="#64748b",linewidth=.3)+
      ggplot2::scale_fill_identity(name=paste(title,unit),breaks=unique(x$.fill),labels=if(is.null(cfg$breaks)) as.character(x$.value[match(unique(x$.fill),x$.fill)]) else as.character(x$.group[match(unique(x$.fill),x$.fill)]),guide="legend")+ggplot2::geom_sf_text(ggplot2::aes(label=.name),size=3)+
      ggplot2::theme_void()+ggplot2::labs(title=paste(title,unit),caption="Colors match the interactive map; see HTML for legend.")
    ggplot2::ggsave(png,g,width=9,height=8,dpi=300)
  }
  sf::st_write(x,derived,delete_dsn=isTRUE(cfg$overwrite),quiet=TRUE)
  htmlwidgets::saveWidget(m,dest,selfcontained=FALSE)
  summary <- list(rows=nrow(x),missing=sum(is.na(x$.value)),total=sum(x$.value,na.rm=TRUE),output=dest)
  jsonlite::write_json(summary,path(paste0("03_output/",stem,"_validation.json")),auto_unbox=TRUE,pretty=TRUE)
  print(summary)
  invisible(summary)
}
if(sys.nframe()==0) {
  args <- commandArgs(TRUE)
  if(length(args)!=1) stop("Usage: Rscript map.R config.json")
  run_map(jsonlite::fromJSON(args[1]))
}
