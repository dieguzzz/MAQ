import { Home, Award, User } from 'lucide-react';

interface NavigationProps {
  currentView: 'home' | 'badges' | 'profile';
  onViewChange: (view: 'home' | 'badges' | 'profile') => void;
}

export function Navigation({ currentView, onViewChange }: NavigationProps) {
  return (
    <nav className="bg-white border-b border-neutral-200 sticky top-0 z-50 shadow-sm">
      <div className="container mx-auto px-4 max-w-7xl">
        <div className="flex items-center justify-between h-16">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-gradient-to-br from-blue-600 to-red-600 rounded-lg flex items-center justify-center">
              <span className="text-white">🚇</span>
            </div>
            <div>
              <h1 className="text-neutral-900">MetroPTY</h1>
              <p className="text-xs text-neutral-500">Cultura en Movimiento</p>
            </div>
          </div>

          <div className="flex gap-2">
            <button
              onClick={() => onViewChange('home')}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg transition-all ${
                currentView === 'home'
                  ? 'bg-blue-100 text-blue-700'
                  : 'text-neutral-600 hover:bg-neutral-100'
              }`}
            >
              <Home className="w-4 h-4" />
              <span className="hidden sm:inline">Inicio</span>
            </button>
            <button
              onClick={() => onViewChange('badges')}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg transition-all ${
                currentView === 'badges'
                  ? 'bg-blue-100 text-blue-700'
                  : 'text-neutral-600 hover:bg-neutral-100'
              }`}
            >
              <Award className="w-4 h-4" />
              <span className="hidden sm:inline">Logros</span>
            </button>
            <button
              onClick={() => onViewChange('profile')}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg transition-all ${
                currentView === 'profile'
                  ? 'bg-blue-100 text-blue-700'
                  : 'text-neutral-600 hover:bg-neutral-100'
              }`}
            >
              <User className="w-4 h-4" />
              <span className="hidden sm:inline">Perfil</span>
            </button>
          </div>
        </div>
      </div>
    </nav>
  );
}
