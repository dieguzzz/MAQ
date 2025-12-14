import { badges, Badge } from '../data/badges';
import { Lock, Star } from 'lucide-react';

interface BadgeGridProps {
  filter?: 'all' | 'featured' | 'unlocked' | 'locked';
  onBadgeClick: (badge: Badge) => void;
}

export function BadgeGrid({ filter = 'all', onBadgeClick }: BadgeGridProps) {
  const filteredBadges = badges.filter(badge => {
    if (filter === 'featured') return badge.featured;
    if (filter === 'unlocked') return badge.unlocked;
    if (filter === 'locked') return !badge.unlocked;
    return true;
  });

  const getCategoryColor = (category: Badge['category']) => {
    const colors = {
      animal: 'from-green-500 to-emerald-600',
      mythology: 'from-purple-500 to-indigo-600',
      culture: 'from-pink-500 to-rose-600',
      hero: 'from-orange-500 to-red-600',
      architecture: 'from-blue-500 to-cyan-600',
      nature: 'from-lime-500 to-green-600',
      festival: 'from-yellow-500 to-orange-600',
    };
    return colors[category];
  };

  const getRarityBorder = (rarity: Badge['rarity']) => {
    const borders = {
      common: 'border-neutral-300',
      rare: 'border-blue-400',
      epic: 'border-purple-500',
      legendary: 'border-yellow-500',
    };
    return borders[rarity];
  };

  const categoryLabels = {
    animal: 'Fauna',
    mythology: 'Mitología',
    culture: 'Cultura',
    hero: 'Héroes',
    architecture: 'Arquitectura',
    nature: 'Naturaleza',
    festival: 'Festividades',
  };

  const groupedBadges = filteredBadges.reduce((acc, badge) => {
    if (!acc[badge.category]) {
      acc[badge.category] = [];
    }
    acc[badge.category].push(badge);
    return acc;
  }, {} as Record<Badge['category'], Badge[]>);

  return (
    <div className="space-y-8">
      {Object.entries(groupedBadges).map(([category, categoryBadges]) => (
        <div key={category}>
          <h3 className="mb-4 flex items-center gap-2">
            {categoryLabels[category as Badge['category']]}
            <span className="text-sm text-neutral-500">
              ({categoryBadges.filter(b => b.unlocked).length}/{categoryBadges.length})
            </span>
          </h3>
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
            {categoryBadges.map((badge) => (
              <button
                key={badge.id}
                onClick={() => onBadgeClick(badge)}
                className={`
                  group relative bg-white rounded-xl p-4 border-2 transition-all duration-300
                  hover:scale-105 hover:shadow-lg
                  ${getRarityBorder(badge.rarity)}
                  ${!badge.unlocked ? 'opacity-60' : ''}
                `}
              >
                {/* Rarity indicator */}
                {badge.rarity === 'legendary' && (
                  <div className="absolute top-2 right-2">
                    <Star className="w-4 h-4 text-yellow-500 fill-yellow-500" />
                  </div>
                )}

                {/* Icon */}
                <div className={`
                  w-16 h-16 mx-auto mb-3 rounded-full flex items-center justify-center
                  bg-gradient-to-br ${getCategoryColor(badge.category)}
                  ${!badge.unlocked ? 'grayscale' : ''}
                `}>
                  <span className="text-3xl">{badge.unlocked ? badge.icon : '🔒'}</span>
                </div>

                {/* Name */}
                <h4 className="text-sm mb-1 text-center line-clamp-1">
                  {badge.name}
                </h4>

                {/* Description */}
                <p className="text-xs text-neutral-500 text-center line-clamp-2">
                  {badge.description}
                </p>

                {/* Lock overlay */}
                {!badge.unlocked && (
                  <div className="absolute inset-0 flex items-center justify-center bg-black/5 rounded-xl">
                    <Lock className="w-8 h-8 text-neutral-400" />
                  </div>
                )}

                {/* Hover effect */}
                <div className={`
                  absolute inset-0 rounded-xl bg-gradient-to-br ${getCategoryColor(badge.category)}
                  opacity-0 group-hover:opacity-10 transition-opacity
                `} />
              </button>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}
