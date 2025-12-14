import { TrendingUp, Award, Users } from 'lucide-react';

export function Hero() {
  const stats = [
    { icon: Award, label: 'Logros Desbloqueados', value: '12/38' },
    { icon: TrendingUp, label: 'Nivel Actual', value: 'Viajero 🐒' },
    { icon: Users, label: 'Reportes Útiles', value: '47' },
  ];

  return (
    <div className="bg-gradient-to-r from-blue-600 via-blue-700 to-red-600 rounded-2xl p-8 text-white shadow-xl">
      <div className="max-w-3xl">
        <div className="inline-block bg-white/20 backdrop-blur-sm px-4 py-2 rounded-full mb-4">
          <span className="text-sm">🇵🇦 Cultura Panameña en Movimiento</span>
        </div>
        
        <h1 className="mb-3 text-white">Descubre Panamá Viajando</h1>
        <p className="text-lg text-blue-50 mb-6">
          Cada viaje en el Metro de Panamá es una oportunidad para aprender sobre nuestra rica cultura.
          Desbloquea logros únicos inspirados en animales, leyendas, héroes y tradiciones panameñas.
        </p>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mt-8">
          {stats.map((stat, index) => (
            <div key={index} className="bg-white/10 backdrop-blur-sm rounded-xl p-4 border border-white/20">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-white/20 rounded-lg flex items-center justify-center">
                  <stat.icon className="w-5 h-5" />
                </div>
                <div>
                  <p className="text-xs text-blue-100">{stat.label}</p>
                  <p className="text-white">{stat.value}</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
