// 0x16000EA0
const GeoLayout star_geo[] = {
   GEO_SHADOW(SHADOW_CIRCLE_4_VERTS, 0x9B, 100),
   GEO_OPEN_NODE(),
      GEO_SCALE(0x00, 16384),
      GEO_OPEN_NODE(),
         GEO_ASM(0, geo_mario_set_player_colors),
         GEO_DISPLAY_LIST(LAYER_OPAQUE, star_seg3_dl_0302B870),
         GEO_DISPLAY_LIST(LAYER_ALPHA, star_seg3_dl_0302BA18),
      GEO_CLOSE_NODE(),
   GEO_CLOSE_NODE(),
   GEO_END(),
};
