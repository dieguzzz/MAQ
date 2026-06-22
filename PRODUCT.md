# Product

## Register

product

## Users
Panama Metro commuters — daily riders checking real-time station status, crowd levels, and delays before and during their commute. Primary context: standing on a platform or walking to a station, phone in hand, glancing for 5-10 seconds. Secondary: planning a route from home or office. Mix of young professionals and students, Spanish-speaking, on mid-range Android phones with variable network quality.

## Product Purpose
MetroPTY is a collaborative real-time status app for the Panama Metro system. Users report station conditions (crowd levels, delays, closures), verify each other's reports Waze-style, and earn points/badges for contributions. Success looks like: a commuter opens the app, instantly sees which stations are crowded, picks the best route, and maybe drops a quick report to help others. The gamification makes contributing feel rewarding, not like a chore.

## Brand Personality
Friendly, Reliable, Fun — like a helpful friend who knows the metro system inside out. Approachable enough that anyone picks it up instantly, trustworthy enough that you check it every morning, and just playful enough (through gamification) to keep you coming back. Not childish, not corporate — warm competence.

## Anti-references
- Generic government transit apps: gray, cluttered, information-overload interfaces that feel like they were built by committee. No bureaucratic UI.
- Lifeless data displays: plain tables of arrival times with no personality. The app should feel alive and community-driven.
- Over-complicated navigation: no deep menu hierarchies. The map is the app; everything else is one tap away.

## Design Principles
1. **Map-first, always** — The map is the primary interface. Everything else (reports, routes, profile) supports the map experience. Don't bury the most important information under navigation.
2. **Glanceable status** — A commuter should understand station conditions in under 3 seconds. Color-coded states, clear iconography, no reading required.
3. **Reward the community** — Make reporting feel good. Points, streaks, badges, and leaderboards aren't decoration — they're the engine that keeps data fresh.
4. **Trust through transparency** — Show report freshness, verification counts, and data confidence. Users trust crowdsourced data when they can see the crowd behind it.
5. **Panama pride** — This is a local app for a local system. The design should feel like it belongs in Panama City, not a generic template.

## Accessibility & Inclusion
- WCAG 2.1 AA minimum (the Flutter app already has high-contrast mode support)
- Color-blind safe status indicators: don't rely on color alone for Normal/Moderate/Full/Closed states — pair with icons or text labels
- Reduced motion support for all animations
- Touch targets minimum 44px for mobile-first usage
- Spanish (es-PA) as primary language
