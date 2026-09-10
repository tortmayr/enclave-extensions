#!/bin/bash
# Copyright (C) 2026 EclipseSource GmbH and others.
#
# This program and the accompanying materials are made available under the
# terms of the MIT License, which is available in the project root.
#
# SPDX-License-Identifier: MIT

# Point Playwright at the shared browser installation (ffmpeg for video
# recording lives there; install.sh populates it at build time).
export PLAYWRIGHT_BROWSERS_PATH=/opt/playwright-browsers
