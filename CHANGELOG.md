# CHANGELOG

<!-- version list -->

## v1.3.0 (2026-06-02)

### Continuous Integration

- Add uptime-kuma to compose validation matrix
  ([`2ce1a09`](https://github.com/ansh-info/homelab/commit/2ce1a091b7e3e980ad408fb1ae074db1860ef7ca))

### Documentation

- Add stack guide for uptime-kuma
  ([`a237aa4`](https://github.com/ansh-info/homelab/commit/a237aa4c31653e4ca63a860793ae32ac954701e4))

- Add uptime-kuma to README and docs index
  ([`369fbbb`](https://github.com/ansh-info/homelab/commit/369fbbb29e6451590dccced550dde4316417dcdc))

- Add uptime-kuma variables to VARIABLES.md
  ([`22fcd1b`](https://github.com/ansh-info/homelab/commit/22fcd1b1039287228e416c244b73a72433203c15))

- Update CLAUDE.md and AGENTS.md stack lists for uptime-kuma
  ([`6b41055`](https://github.com/ansh-info/homelab/commit/6b4105505acb6305ee324382383475b4d853b93a))

### Features

- Add uptime-kuma stack for service monitoring
  ([`cca3302`](https://github.com/ansh-info/homelab/commit/cca33021ca8ac6b4f6cf77c020a30d198ce0cd17))


## v1.2.1 (2026-06-01)

### Bug Fixes

- Gitignore stack.env files to prevent secret leaks
  ([`0593b19`](https://github.com/ansh-info/homelab/commit/0593b1923df65f6b477996acc2b2fa41a2162567))

- Harden jellyfin-arr-stack security and logging
  ([`7ebc830`](https://github.com/ansh-info/homelab/commit/7ebc8302d776e80f08e54b666ca84e627597a5f9))

- Restrict Watchtower docker.sock to read-only and remove debug mode
  ([`580e501`](https://github.com/ansh-info/homelab/commit/580e501ba6429ba24e70be2eae76254eeb014473))

### Documentation

- Update all docs to reflect security hardening changes
  ([`1a7b01d`](https://github.com/ansh-info/homelab/commit/1a7b01d6c4bfff8eadb380fbd1639f274623ea78))


## v1.2.0 (2026-05-31)

### Continuous Integration

- Add actual-budget to compose validation matrix
  ([`ff0a8b0`](https://github.com/ansh-info/homelab/commit/ff0a8b0efd22a9e17d001b3de941074847a84667))

### Documentation

- Add actual-budget to README and docs index
  ([`c97f864`](https://github.com/ansh-info/homelab/commit/c97f86491da7d632d175aee6ddd7622cae5426d6))

- Add actual-budget variables to VARIABLES.md
  ([`5bbb80f`](https://github.com/ansh-info/homelab/commit/5bbb80f849e03e768cbd38b14eb58609e2e19783))

- Add CLAUDE.md for Claude Code guidance
  ([`d3bca46`](https://github.com/ansh-info/homelab/commit/d3bca46d8537ffd4d1a38d32e69646c3b88f9d1a))

- Add stack guide for actual-budget
  ([`a601c05`](https://github.com/ansh-info/homelab/commit/a601c05023895fd448716209064dadb068a4bcbe))

- Document Tailscale NAT keepalive fix for DERP relay fallback
  ([`2efac4e`](https://github.com/ansh-info/homelab/commit/2efac4ea3a02367cbfab6d7bd45a5ba1ee3b4eaf))

- Fix markdown lint and add cross-references to CLAUDE.md
  ([`bb86cc6`](https://github.com/ansh-info/homelab/commit/bb86cc68794defd0e45f45db0566ea2317087257))

- Update CLAUDE.md and AGENTS.md stack lists
  ([`3516ea1`](https://github.com/ansh-info/homelab/commit/3516ea11fa730b59192be10c0666ebe474d5e768))

### Features

- Add actual-budget stack for personal finance management
  ([`6d78267`](https://github.com/ansh-info/homelab/commit/6d78267dcbece379af48537b370f63c9a4f53dc7))


## v1.1.2 (2026-03-30)

### Bug Fixes

- Clean zshrc lazy loading
  ([`0d9ebad`](https://github.com/ansh-info/homelab/commit/0d9ebad770522c9e6d94901400d16d16d173b9e0))


## v1.1.1 (2026-03-30)

### Bug Fixes

- Clean tmux config and docs
  ([`dff1574`](https://github.com/ansh-info/homelab/commit/dff1574333bdf792e90d2dae02a8732b0f3e0677))

### Chores

- Remove stale utils folder
  ([`014e204`](https://github.com/ansh-info/homelab/commit/014e204d7203014773e8e8aed473c48e6c8f1337))

### Documentation

- Document discord guild setup for openclaw
  ([`0306c61`](https://github.com/ansh-info/homelab/commit/0306c61ff67169add858ad61f565cab7aecc3eb4))

- Modernize zshrc setup
  ([`f2953f7`](https://github.com/ansh-info/homelab/commit/f2953f7731bebccc1ac600910cb5115ef90a89d2))

- Update agent guidance after utils removal
  ([`7c61d82`](https://github.com/ansh-info/homelab/commit/7c61d82119d37da826fa3c690b227c8674b70744))


## v1.1.0 (2026-03-29)

### Bug Fixes

- Attach homarr to proxy network
  ([`0527333`](https://github.com/ansh-info/homelab/commit/0527333a9a216a305d9b243fec9e999edc4364b8))

### Chores

- Ignore local superpowers notes
  ([`a47983b`](https://github.com/ansh-info/homelab/commit/a47983bc5fbf2627b963144a2fa0fe11a44c3f36))

### Continuous Integration

- Validate aerospace toml with python
  ([`7a23f05`](https://github.com/ansh-info/homelab/commit/7a23f05c4126bf446e48fef1fe2c7eef29e45fc1))

- Validate openclaw compose stack
  ([`6794a40`](https://github.com/ansh-info/homelab/commit/6794a404a62a8f48533df509bfca3dbb47e5751f))

### Documentation

- Add openclaw stack guide
  ([`cdeead4`](https://github.com/ansh-info/homelab/commit/cdeead4d854547582c3ab35e72f24c8ecb5d52ba))

- Add readme status badges
  ([`7a08d21`](https://github.com/ansh-info/homelab/commit/7a08d21ee60be12c3e3231d16d76fac8fb96b7e7))

- Annotate aerospace config
  ([`495eab9`](https://github.com/ansh-info/homelab/commit/495eab96c9aa769d4135e8d160e590ddf5963e77))

- Clarify watchtower update scope
  ([`782c0bf`](https://github.com/ansh-info/homelab/commit/782c0bfd18a20f9ef76abe0eec7a2b6e59c890e1))

- Document openclaw in shared guides
  ([`8e3d944`](https://github.com/ansh-info/homelab/commit/8e3d944bf4f42b4cc14f1df2a26885d029076be8))

- Refine readme service badges
  ([`3e928c9`](https://github.com/ansh-info/homelab/commit/3e928c9f72a610479c692b05538f2505f65d3140))

- Rewrite aerospace setup guide
  ([`1a058f2`](https://github.com/ansh-info/homelab/commit/1a058f28a17ebbf1a7c995a78556873a20777192))

- Rewrite kitty setup guide
  ([`bf56296`](https://github.com/ansh-info/homelab/commit/bf5629642b88cc60c63ec44fd524289418f92b4a))

- Rewrite tmux setup guide
  ([`406bc44`](https://github.com/ansh-info/homelab/commit/406bc44512559a5c6c8942a1b4dc0127dfa8e771))

- Update agent guidance for openclaw
  ([`cd01377`](https://github.com/ansh-info/homelab/commit/cd013773fdbd8736d323863bb46c58c5415f5eea))

### Features

- Add kitty current theme config
  ([`427843b`](https://github.com/ansh-info/homelab/commit/427843bdef160f8efb827dab55f1ce000fd87896))

- Add openclaw stack files
  ([`fdf9af1`](https://github.com/ansh-info/homelab/commit/fdf9af1c976bb5b58e89b96dae2caa9bc05632b4))


## v1.0.1 (2026-03-28)

### Bug Fixes

- Update release co author
  ([`54da1bb`](https://github.com/ansh-info/homelab/commit/54da1bb411e0a016707169372529f8478d9c6aa7))


## v1.0.0 (2026-03-28)

- Initial Release
