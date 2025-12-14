import { X, Lock, CheckCircle, Trophy } from 'lucide-react';
import { Badge } from '../data/badges';

interface AchievementModalProps {
  badge: Badge;
  onClose: () => void;
}

export function AchievementModal({ badge, onClose }: AchievementModalProps) {
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

  const getRarityLabel = (rarity: Badge['rarity']) => {
    const labels = {
      common: 'Común',
      rare: 'Raro',
      epic: 'Épico',
      legendary: 'Legendario',
    };
    return labels[rarity];
  };

  const getRarityColor = (rarity: Badge['rarity']) => {
    const colors = {
      common: 'text-neutral-600 bg-neutral-100',
      rare: 'text-blue-600 bg-blue-100',
      epic: 'text-purple-600 bg-purple-100',
      legendary: 'text-yellow-600 bg-yellow-100',
    };
    return colors[rarity];
  };

  const categoryLabels = {
    animal: 'Fauna Panameña',
    mythology: 'Mitología',
    culture: 'Cultura Popular',
    hero: 'Héroes Nacionales',
    architecture: 'Arquitectura',
    nature: 'Naturaleza',
    festival: 'Festividades',
  };

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl max-w-lg w-full max-h-[90vh] overflow-y-auto shadow-2xl">
        {/* Header with gradient */}
        <div className={`relative bg-gradient-to-br ${getCategoryColor(badge.category)} p-8 text-white rounded-t-2xl`}>
          <button
            onClick={onClose}
            className="absolute top-4 right-4 w-8 h-8 bg-white/20 hover:bg-white/30 rounded-full flex items-center justify-center transition-colors"
          >
            <X className="w-5 h-5" />
          </button>

          {/* Icon */}
          <div className="w-24 h-24 mx-auto bg-white/20 backdrop-blur-sm rounded-full flex items-center justify-center mb-4">
            <span className="text-6xl">{badge.unlocked ? badge.icon : '🔒'}</span>
          </div>

          {/* Name and Category */}
          <h2 className="text-center mb-2 text-white">{badge.name}</h2>
          <p className="text-center text-white/80 text-sm">{categoryLabels[badge.category]}</p>

          {/* Rarity Badge */}
          <div className="flex justify-center mt-4">
            <span className={`px-4 py-1 rounded-full text-sm ${getRarityColor(badge.rarity)}`}>
              {getRarityLabel(badge.rarity)}
            </span>
          </div>
        </div>

        {/* Content */}
        <div className="p-6 space-y-6">
          {/* Status */}
          <div className={`flex items-center gap-3 p-4 rounded-xl ${
            badge.unlocked ? 'bg-green-50 border border-green-200' : 'bg-neutral-50 border border-neutral-200'
          }`}>
            {badge.unlocked ? (
              <>
                <CheckCircle className="w-6 h-6 text-green-600 flex-shrink-0" />
                <div>
                  <p className="text-green-900">¡Logro Desbloqueado!</p>
                  <p className="text-sm text-green-600">{badge.description}</p>
                </div>
              </>
            ) : (
              <>
                <Lock className="w-6 h-6 text-neutral-400 flex-shrink-0" />
                <div>
                  <p className="text-neutral-700">Logro Bloqueado</p>
                  <p className="text-sm text-neutral-500">{badge.description}</p>
                </div>
              </>
            )}
          </div>

          {/* Cultural Information */}
          <div>
            <div className="flex items-center gap-2 mb-2">
              <span className="text-xl">🇵🇦</span>
              <h3>Información Cultural</h3>
            </div>
            <p className="text-neutral-700 leading-relaxed">
              {badge.culturalInfo}
            </p>
          </div>

          {/* Unlock Condition */}
          <div>
            <div className="flex items-center gap-2 mb-2">
              <Trophy className="w-5 h-5 text-neutral-600" />
              <h3>Cómo Desbloquearlo</h3>
            </div>
            <p className="text-neutral-700 leading-relaxed">
              {badge.unlockCondition}
            </p>
          </div>

          {/* Action Button */}
          <button
            onClick={onClose}
            className={`w-full py-3 rounded-xl transition-colors ${
              badge.unlocked
                ? 'bg-gradient-to-r ' + getCategoryColor(badge.category) + ' text-white hover:opacity-90'
                : 'bg-neutral-200 text-neutral-700 hover:bg-neutral-300'
            }`}
          >
            {badge.unlocked ? '¡Genial!' : 'Entendido'}
          </button>
        </div>
      </div>
    </div>
  );
}
