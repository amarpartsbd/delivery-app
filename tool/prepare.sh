#!/usr/bin/env bash
#
# Patches the template with a tenant's branding before building.
# Required env: APP_NAME PACKAGE_ID API_URL VERSION_NAME VERSION_CODE
# Optional env: ICON_URL PRIMARY_COLOR
#
# Works for the staff apps (delivery / admin): config.dart is {apiBaseUrl, appName}.
# The google-services.json block is a no-op when the app has no Firebase config.
#
set -euo pipefail

: "${APP_NAME:?}"; : "${PACKAGE_ID:?}"; : "${API_URL:?}"
: "${PRIMARY_COLOR:=#16a34a}"; : "${VERSION_NAME:=1.0.0}"; : "${VERSION_CODE:=1}"

echo "→ Preparing build: $APP_NAME ($PACKAGE_ID) v$VERSION_NAME+$VERSION_CODE"

# 1) App config (API URL + name)
cat > lib/config.dart <<EOF
class AppConfig {
  static const String apiBaseUrl = '${API_URL}';
  static const String appName = '${APP_NAME}';
}
EOF

# 2) Android applicationId + label + version
sed -i "s#applicationId = \"[^\"]*\"#applicationId = \"${PACKAGE_ID}\"#" android/app/build.gradle.kts
sed -i "s#android:label=\"[^\"]*\"#android:label=\"${APP_NAME}\"#" android/app/src/main/AndroidManifest.xml
sed -i "s#^version: .*#version: ${VERSION_NAME}+${VERSION_CODE}#" pubspec.yaml

# 2b) Point Firebase (if present) at this tenant's package id so the
#     google-services plugin finds a matching client.
if [ -f android/app/google-services.json ]; then
  echo "→ Rewriting google-services.json package_name → ${PACKAGE_ID}"
  sed -i "s#\"package_name\": *\"[^\"]*\"#\"package_name\": \"${PACKAGE_ID}\"#g" android/app/google-services.json
fi

# 3) Launcher icon (download if provided; else keep default)
mkdir -p assets
if [ -n "${ICON_URL:-}" ]; then
  echo "→ Downloading icon"
  curl -fsSL "${ICON_URL}" -o assets/icon.png || echo "  (icon download failed, using default)"
fi

# Padded adaptive foreground so Android's mask doesn't crop the artwork.
if [ -f assets/icon.png ]; then
  if command -v convert >/dev/null 2>&1; then
    convert assets/icon.png -resize 62%x62% -background none -gravity center -extent 1024x1024 assets/icon_fg.png 2>/dev/null || cp assets/icon.png assets/icon_fg.png
  else
    cp assets/icon.png assets/icon_fg.png
  fi
fi

cat > flutter_launcher_icons.yaml <<EOF
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icon.png"
  adaptive_icon_background: "${PRIMARY_COLOR}"
  adaptive_icon_foreground: "assets/icon_fg.png"
  min_sdk_android: 23
EOF

cat > flutter_native_splash.yaml <<EOF
flutter_native_splash:
  color: "${PRIMARY_COLOR}"
  android: true
  ios: false
  android_12:
    color: "${PRIMARY_COLOR}"
EOF

flutter pub get
if [ -f assets/icon.png ]; then
  dart run flutter_launcher_icons -f flutter_launcher_icons.yaml || echo "  (launcher_icons skipped)"
fi
dart run flutter_native_splash:create || echo "  (native_splash skipped)"

echo "→ Prepare done."
