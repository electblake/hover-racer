# Galactic Racer vehicle reference summary

Reference date: **2026-10-25**, America/Toronto. Product: **Star Wars: Galactic Racer**, by Fuse Games / Secret Mode. No exact executable build or patch version was established by these sources. The official vehicle guide is dated September 29, 2026; Xbox Wire's preview is dated June 23, 2026. These are dated descriptions, not verified current tuning values.

## Official vehicle identities

Source: [StarWars.com vehicle guide](www.starwars.com/news/star-wars-galactic-racer-vehicle-guide.md).

| Class | Handling identity | Distinctive maneuver / tradeoff |
| --- | --- | --- |
| Landspeeder | Stable, durable, approachable | Drifts through corners; trades outright pace for resilience. |
| Speeder bike | Fast, light, vulnerable | Kinetic Burst adds speed; control and cornering demand practice. |
| Skim speeder | Banked turns, balance of agility and resilience | Knife Edge tightens cornering; slow acceleration rewards momentum conservation. |
| Podracer | Very high speed, separate engines and cockpit | Airbrake tightens turns with a substantial speed penalty. |

The [official game site](starwarsgalacticracer.com/index.md) confirms the four classes and distinct physics/playstyles. It does not provide equations, force curves, suspension parameters, or tuning constants.

## Boost and build systems

[Xbox Wire's hands-on preview](news.xbox.com/en-us/2026/06/23/star-wars-galactic-racer-turns-podracing-into-roguelite/index.md) describes two boost resources: a replenishing Afterburner and a stronger Ramjet that risks catastrophic overheating. Upgrades affect vehicle attributes and class-specific maneuvers. Treat the preview as contemporary observed gameplay, not an exhaustive developer specification.

## Community glossary: useful implementation vocabulary

Source: user-supplied [Games Lantern glossary](galacticracer.gameslantern.com/glossary.md), independently maintained and not developer-endorsed.

- Speed describes unboosted maximum velocity. Cornering and Maneuvering are separate concepts; the latter relates to class-specific techniques.
- Afterburner and Ramjet each have separate entries for the mechanic and its associated performance stat. Preserve this distinction when using their terminology.
- Ramjet heat interacts with cooling, burning, and disabling effects. Redlining describes the region near overheating.
- Energy powers abilities; Battery determines capacity. This resource is conceptually separate from boost and heat.
- Perfect Landing rewards pitch alignment; Slipstreaming rewards following another racer. Takedowns refill Afterburner.
- Some entries, including Blinded and Overclocked, lack behavioral definitions. Do not invent effects from their names.

The [community class comparison](galacticracer.gameslantern.com/vehicle-classes.md) describes Kinetic Burst as braking/tighter steering followed by a speed return on release. The official guide compresses this into a temporary speed boost. Preserve both descriptions; exact timing, energy retention, and input behavior need gameplay verification.

The [vehicle catalog](galacticracer.gameslantern.com/vehicles.md) is a model/kit research entry point. Its linked renders and interactive models were not captured in this text bundle.

## Hover Racer design implications — inference, not source facts

The user identifies Galactic Racer as vehicle inspiration for this project. No runtime behavior of Hover Racer was evaluated here.

1. Define a clear handling identity before choosing numerical tuning: stable drifting, light acceleration, banking with momentum, or high-speed airbraking.
2. Consider replenishing boost and heat-limited boost as distinct driver decisions, with readable resource feedback.
3. Separate base performance, class-specific maneuver behavior, and temporary status modifiers in a future design specification.
4. Test maneuver tradeoffs explicitly: speed lost while braking, speed retained during a drift, turn radius versus bank angle, and recovery after boost release.

These are possible directions for later design work, not approved features or changes to the current game.

## Limits and compatibility

No Godot compatibility, integration API, numerical physics model, or breaking-change information is supplied by these references. Do not treat descriptive vehicle lore as a physical simulation specification. The snapshot combines a pre-release preview, official promotional material, and community documentation; detailed mechanics may differ across builds. All six requested pages were captured; `/llms.txt` was absent (HTTP 404) on all four domains. See [capture manifest](capture-manifest.json).
