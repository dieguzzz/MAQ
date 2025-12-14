import { useState } from 'react';
import { BadgeGrid } from './components/BadgeGrid';
import { UserProfile } from './components/UserProfile';
import { AchievementModal } from './components/AchievementModal';
import { Navigation } from './components/Navigation';
import { Hero } from './components/Hero';

export default function App() {
  const [selectedBadge, setSelectedBadge] = useState<any>(null);
  const [currentView, setCurrentView] = useState<'home' | 'badges' | 'profile'>('home');

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-red-50">
      <Navigation currentView={currentView} onViewChange={setCurrentView} />
      
      <main className="container mx-auto px-4 py-6 max-w-7xl">
        {currentView === 'home' && (
          <>
            <Hero />
            <div className="mt-8">
              <h2 className="mb-6 text-center">Logros Destacados</h2>
              <BadgeGrid
                filter="featured"
                onBadgeClick={setSelectedBadge}
              />
            </div>
          </>
        )}

        {currentView === 'badges' && (
          <div>
            <div className="text-center mb-8">
              <h1 className="mb-2">Colección de Logros</h1>
              <p className="text-neutral-600">Descubre y desbloquea elementos de la cultura panameña</p>
            </div>
            <BadgeGrid onBadgeClick={setSelectedBadge} />
          </div>
        )}

        {currentView === 'profile' && (
          <UserProfile />
        )}
      </main>

      {selectedBadge && (
        <AchievementModal
          badge={selectedBadge}
          onClose={() => setSelectedBadge(null)}
        />
      )}
    </div>
  );
}
