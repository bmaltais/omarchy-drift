# shellcheck shell=bash disable=SC2034
# The README animation: open the panel from the bar icon, pick atmospheres, follow the day and the weather, search a city, move the sliders.
# Record with: scripts/tour.sh tours/hero.sh --install   (coordinates below are for the 1440x900 session)
TOUR_OUT=screenshots/drift.avif
TOUR_SIZE=1440x900
TOUR_LAYER=omarchy-drift-settings
TOUR_STEPS=6
TOUR_MAX_SECONDS=240

tour_prepare() {
  # Start from a known state in the sandbox: on, Ember, no day or weather yet, a livelier speed so motion shows in a short film.
  mkdir -p "$HOME/.local/state/omarchy-drift"
  cat > "$HOME/.local/state/omarchy-drift/settings.json" <<JSON
{"lit": true, "atmosphere": "Ember", "wander": false, "followDay": false, "followWeather": false,
 "speed": 1.3, "grain": 0.35, "blobs": 6, "restDrift": false, "showTime": false, "location": null}
JSON
}

tour_play() {
  cap "Drift is a calm animated wallpaper"
  sleep 3.5

  cap "Click the bar icon to open the panel"
  click 839 13 1.5
  wait_until "layer_up omarchy-drift-settings" 20
  sleep 1.5

  cap "Pick an atmosphere from the list"
  click 855 228 0.9; click 950 271 2.4    # Iris
  click 855 228 0.9; click 950 297 2.4    # Lagoon
  click 855 228 0.9; click 950 323 2.4    # Dusk

  cap "Follow the day and the colours follow the hour"
  click 978 323 2.5
  click 978 380 3

  cap "Follow the weather and search any city"
  click 978 437 3
  click 902 437 1.2
  typed "vict"
  sleep 3.5
  click 830 562 4          # first match, below the "Current location" entry

  cap "Tune the speed, the grain and the blobs"
  click 960 529 1.8
  click 940 671 1.8
  click 880 714 1.8
  click 940 714 2

  cap "Close the panel with the cross"
  click 1000 51 3
}
