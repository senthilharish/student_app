#!/bin/bash
set -e
cd "$(dirname "$0")"
flutter build web --output=build/web-user
firebase deploy --only hosting:user --project tracker-aa86b
