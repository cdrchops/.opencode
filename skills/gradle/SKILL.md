---
name: gradle
description: "Load when building, packaging, or configuring the project through Gradle — running builds, assembling distributable artifacts such as fat jars, and deciding what those artifacts contain, including the service registrations that must survive aggregation. Java language conventions belong to `java`."
license: MIT
provenance: AI-authored, .opencode#2557
---

<!-- SPDX-FileCopyrightText: 2026 Michael Conrad -->
<!-- SPDX-License-Identifier: MIT -->
<!-- Provenance: AI-authored, .opencode#2557; packaging depth in references/packaging-spi.md -->

# gradle

This card owns Gradle as a build/run tool — running builds, configuring the
build, and assembling distributable artifacts. It stays top-level because its
intent space is not contained by Java work: build configuration touches no Java
code, and a future Kotlin/Scala card would need it.

## Wrapper discipline

- Invoke builds through the wrapper (`./gradlew`) when the repository ships
  one — the wrapper pins the distribution version the project was built to
  work with; a bare `gradle` uses whatever the machine has.
- When the repository has no wrapper, the canonical command comes from the
  repo's declared build manifest — ask when the manifest does not declare it;
  never guess.

## Canonical-command sourcing

Build/test commands come from the repository's declared build manifest. The
manifest's declared Gradle commands are the canonical ones — run them as
declared; do not substitute task lists of your own invention.

## Packaging depth

Fat-jar assembly — what the artifact contains and which service registrations
must survive aggregation — is the detail card:
[packaging-spi.md](references/packaging-spi.md). Load it when configuring
shadowJar or any dependency-bundling jar task.

🤖 Co-authored with AI: OpenCode (huggingface/zai-org/GLM-5.3-Flash)
