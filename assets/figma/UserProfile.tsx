import { TrendingUp, Award, Star, Target, Calendar } from 'lucide-react';
import { badges } from '../data/badges';

export function UserProfile() {
  const userLevels = [
    { name: 'Novato', icon: '🦎', emoji: 'Gecko', xpRequired: 0, current: false },
    { name: 'Viajero', icon: '🐒', emoji: 'Mono Tití', xpRequired: 100, current: true },
    { name: 'Reportero', icon: '🦅', emoji: 'Águila Harpía', xpRequired: 500, current: false },
    { name: 'Experto', icon: '⚔️', emoji: 'Victoriano Lorenzo', xpRequired: 1500, current: false },
    { name: 'Héroe', icon: '🛶', emoji: 'Urracá', xpRequired: 5000, current: false },
  ];

  const currentLevel = userLevels.find(l => l.current);
  const nextLevel = userLevels[userLevels.findIndex(l => l.current) + 1];
  const currentXP = 247;
  const progress = nextLevel ? (currentXP / nextLevel.xpRequired) * 100 : 100;

  const unlockedBadges = badges.filter(b => b.unlocked);
  const totalBadges = badges.length;
  const badgesByRarity = {
    legendary: unlockedBadges.filter(b => b.rarity === 'legendary').length,
    epic: unlockedBadges.filter(b => b.rarity === 'epic').length,
    rare: unlockedBadges.filter(b => b.rarity === 'rare').length,
    common: unlockedBadges.filter(b => b.rarity === 'common').length,
  };

  const stats = [
    { label: 'Viajes Totales', value: '156', icon: TrendingUp, color: 'text-blue-600', bg: 'bg-blue-100' },
    { label: 'Reportes Útiles', value: '47', icon: Target, color: 'text-green-600', bg: 'bg-green-100' },
    { label: 'Racha Actual', value: '7 días', icon: Calendar, color: 'text-orange-600', bg: 'bg-orange-100' },
    { label: 'Logros Desbloqueados', value: `${unlockedBadges.length}/${totalBadges}`, icon: Award, color: 'text-purple-600', bg: 'bg-purple-100' },
  ];

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* Profile Header */}
      <div className="bg-white rounded-2xl p-8 shadow-sm border border-neutral-200">
        <div className="flex flex-col md:flex-row items-center gap-6">
          <div className="w-24 h-24 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center text-5xl">
            {currentLevel?.icon}
          </div>
          <div className="flex-1 text-center md:text-left">
            <h1 className="mb-1">Viajero del Metro</h1>
            <p className="text-neutral-600 mb-3">Nivel {currentLevel?.name} - {currentLevel?.emoji}</p>
            
            {/* XP Progress */}
            {nextLevel && (
              <div className="space-y-2">
                <div className="flex justify-between text-sm text-neutral-600">
                  <span>{currentXP} XP</span>
                  <span>{nextLevel.xpRequired} XP</span>
                </div>
                <div className="w-full bg-neutral-200 rounded-full h-3 overflow-hidden">
                  <div 
                    className="h-full bg-gradient-to-r from-blue-500 to-purple-600 rounded-full transition-all duration-500"
                    style={{ width: `${progress}%` }}
                  />
                </div>
                <p className="text-sm text-neutral-500">
                  {nextLevel.xpRequired - currentXP} XP hasta {nextLevel.name}
                </p>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {stats.map((stat, index) => (
          <div key={index} className="bg-white rounded-xl p-5 shadow-sm border border-neutral-200">
            <div className={`w-12 h-12 ${stat.bg} rounded-lg flex items-center justify-center mb-3`}>
              <stat.icon className={`w-6 h-6 ${stat.color}`} />
            </div>
            <p className="text-2xl mb-1">{stat.value}</p>
            <p className="text-sm text-neutral-600">{stat.label}</p>
          </div>
        ))}
      </div>

      {/* Levels Progress */}
      <div className="bg-white rounded-2xl p-6 shadow-sm border border-neutral-200">
        <h2 className="mb-6">Progreso de Niveles</h2>
        <div className="space-y-4">
          {userLevels.map((level, index) => (
            <div key={index} className="flex items-center gap-4">
              <div className={`
                w-16 h-16 rounded-full flex items-center justify-center text-2xl
                ${level.current ? 'bg-gradient-to-br from-blue-500 to-purple-600' : 
                  currentXP >= level.xpRequired ? 'bg-green-100' : 'bg-neutral-100'}
              `}>
                {level.icon}
              </div>
              <div className="flex-1">
                <div className="flex items-center gap-2 mb-1">
                  <p className={level.current ? 'text-blue-600' : ''}>
                    {level.name}
                  </p>
                  {level.current && (
                    <span className="px-2 py-1 bg-blue-100 text-blue-700 text-xs rounded-full">
                      Actual
                    </span>
                  )}
                  {currentXP >= level.xpRequired && !level.current && (
                    <span className="text-green-600 text-xs">✓ Completado</span>
                  )}
                </div>
                <p className="text-sm text-neutral-500">{level.emoji}</p>
              </div>
              <div className="text-right">
                <p className="text-neutral-500">{level.xpRequired} XP</p>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Badge Collection Summary */}
      <div className="bg-white rounded-2xl p-6 shadow-sm border border-neutral-200">
        <h2 className="mb-6">Colección de Logros</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="text-center p-4 rounded-xl bg-neutral-50">
            <div className="flex items-center justify-center gap-2 mb-2">
              <Star className="w-5 h-5 text-yellow-500 fill-yellow-500" />
              <p className="text-2xl">{badgesByRarity.legendary}</p>
            </div>
            <p className="text-sm text-neutral-600">Legendarios</p>
          </div>
          <div className="text-center p-4 rounded-xl bg-neutral-50">
            <div className="flex items-center justify-center gap-2 mb-2">
              <Star className="w-5 h-5 text-purple-500 fill-purple-500" />
              <p className="text-2xl">{badgesByRarity.epic}</p>
            </div>
            <p className="text-sm text-neutral-600">Épicos</p>
          </div>
          <div className="text-center p-4 rounded-xl bg-neutral-50">
            <div className="flex items-center justify-center gap-2 mb-2">
              <Star className="w-5 h-5 text-blue-500 fill-blue-500" />
              <p className="text-2xl">{badgesByRarity.rare}</p>
            </div>
            <p className="text-sm text-neutral-600">Raros</p>
          </div>
          <div className="text-center p-4 rounded-xl bg-neutral-50">
            <div className="flex items-center justify-center gap-2 mb-2">
              <Star className="w-5 h-5 text-neutral-400 fill-neutral-400" />
              <p className="text-2xl">{badgesByRarity.common}</p>
            </div>
            <p className="text-sm text-neutral-600">Comunes</p>
          </div>
        </div>

        <div className="mt-6 p-4 bg-gradient-to-r from-blue-50 to-purple-50 rounded-xl border border-blue-200">
          <p className="text-center text-neutral-700">
            <span className="text-2xl mr-2">🎯</span>
            Has completado el <strong>{Math.round((unlockedBadges.length / totalBadges) * 100)}%</strong> de la colección
          </p>
        </div>
      </div>

      {/* Recent Achievements */}
      <div className="bg-white rounded-2xl p-6 shadow-sm border border-neutral-200">
        <h2 className="mb-4">Logros Recientes</h2>
        <div className="space-y-3">
          {unlockedBadges.slice(0, 5).map((badge) => (
            <div key={badge.id} className="flex items-center gap-4 p-3 bg-neutral-50 rounded-xl">
              <div className="w-12 h-12 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center text-2xl">
                {badge.icon}
              </div>
              <div className="flex-1">
                <p className="mb-0.5">{badge.name}</p>
                <p className="text-sm text-neutral-500">{badge.description}</p>
              </div>
              <Star className="w-5 h-5 text-yellow-500 fill-yellow-500" />
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
