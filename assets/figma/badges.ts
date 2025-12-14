export interface Badge {
  id: string;
  name: string;
  icon: string;
  category: 'animal' | 'mythology' | 'culture' | 'hero' | 'architecture' | 'nature' | 'festival';
  description: string;
  culturalInfo: string;
  unlockCondition: string;
  rarity: 'common' | 'rare' | 'epic' | 'legendary';
  unlocked: boolean;
  featured?: boolean;
}

export const badges: Badge[] = [
  // Animales
  {
    id: 'aguila-harpia',
    name: 'Águila Harpía',
    icon: '🦅',
    category: 'animal',
    description: 'Vista Aguda',
    culturalInfo: 'Ave nacional de Panamá, símbolo de fuerza y visión. Es una de las águilas más poderosas del mundo y habita en la selva del Darién.',
    unlockCondition: 'Reporta 50 situaciones con alta precisión',
    rarity: 'legendary',
    unlocked: true,
    featured: true
  },
  {
    id: 'mono-titi',
    name: 'Mono Tití',
    icon: '🐒',
    category: 'animal',
    description: 'Velocidad y Agilidad',
    culturalInfo: 'Pequeño primate en peligro de extinción, ágil y rápido. Representa la rapidez con la que te mueves por el metro.',
    unlockCondition: 'Completa 10 viajes en menos de 15 minutos',
    rarity: 'rare',
    unlocked: true
  },
  {
    id: 'perezoso',
    name: 'Perezoso',
    icon: '🦥',
    category: 'animal',
    description: 'Paciencia Tropical',
    culturalInfo: 'Representa la tranquilidad panameña. Perfecto para cuando el metro va lento pero mantienes la calma.',
    unlockCondition: 'Espera pacientemente 30 minutos por retrasos',
    rarity: 'common',
    unlocked: false
  },
  {
    id: 'guacamaya',
    name: 'Guacamaya Roja',
    icon: '🦜',
    category: 'animal',
    description: 'Colores Vibrantes',
    culturalInfo: 'Ave de colores brillantes que representa la vida tropical de Panamá.',
    unlockCondition: 'Usa todas las líneas del metro',
    rarity: 'epic',
    unlocked: true,
    featured: true
  },
  {
    id: 'rana-dorada',
    name: 'Rana Dorada',
    icon: '🐸',
    category: 'animal',
    description: 'Tesoro Escondido',
    culturalInfo: 'Símbolo nacional en peligro de extinción. Representa los tesoros únicos que descubres en la ciudad.',
    unlockCondition: 'Descubre 5 estaciones nuevas',
    rarity: 'legendary',
    unlocked: false
  },
  {
    id: 'gecko',
    name: 'Gecko',
    icon: '🦎',
    category: 'animal',
    description: 'Siempre Presente',
    culturalInfo: 'Común en todo Panamá, ágil y adaptable. Tu primer logro como usuario de MetroPTY.',
    unlockCondition: 'Completa tu primer viaje',
    rarity: 'common',
    unlocked: true
  },

  // Mitología
  {
    id: 'tulivieja',
    name: 'La Tulivieja',
    icon: '🌊',
    category: 'mythology',
    description: 'Alerta de Lluvia',
    culturalInfo: 'Espíritu femenino de ríos y quebradas con cabellera larga que cubre el rostro. Aparece en días lluviosos.',
    unlockCondition: 'Usa el metro durante 5 días lluviosos',
    rarity: 'rare',
    unlocked: false
  },
  {
    id: 'madre-agua',
    name: 'Madre de Agua',
    icon: '💧',
    category: 'mythology',
    description: 'Flujo Perfecto',
    culturalInfo: 'Diosa de ríos y mares, protectora de las aguas. Representa el flujo perfecto del metro.',
    unlockCondition: 'Completa 20 viajes sin retrasos',
    rarity: 'epic',
    unlocked: true,
    featured: true
  },
  {
    id: 'diablicos',
    name: 'Diablicos Limpios',
    icon: '👹',
    category: 'mythology',
    description: 'Energía y Movimiento',
    culturalInfo: 'Danzantes tradicionales con trajes rojos vibrantes. Representan la energía del carnaval panameño.',
    unlockCondition: 'Viaja durante las festividades de carnaval',
    rarity: 'epic',
    unlocked: false
  },
  {
    id: 'la-guali',
    name: 'La Guali',
    icon: '🌳',
    category: 'mythology',
    description: 'Protector Ecológico',
    culturalInfo: 'Espíritu del bosque, protectora de la naturaleza. Para usuarios conscientes del medio ambiente.',
    unlockCondition: 'Usa el metro en lugar del auto 30 veces',
    rarity: 'rare',
    unlocked: false
  },
  {
    id: 'chorcha',
    name: 'Chorcha',
    icon: '🌀',
    category: 'mythology',
    description: 'Desvío Inesperado',
    culturalInfo: 'Espíritu travieso del viento que desorienta y causa confusión. Aparece con los desvíos.',
    unlockCondition: 'Experimenta tu primer desvío de ruta',
    rarity: 'common',
    unlocked: false
  },

  // Cultura Popular
  {
    id: 'pollera',
    name: 'La Pollera',
    icon: '👗',
    category: 'culture',
    description: 'Elegancia Tradicional',
    culturalInfo: 'Traje típico nacional de Panamá, símbolo de elegancia y tradición. Uno de los vestidos más elaborados de América.',
    unlockCondition: 'Mantén un historial impecable por 30 días',
    rarity: 'legendary',
    unlocked: false
  },
  {
    id: 'tamborito',
    name: 'Tamborito',
    icon: '🥁',
    category: 'culture',
    description: 'Ritmo Perfecto',
    culturalInfo: 'Baile y música tradicional de Panamá. Representa el ritmo constante de tus viajes.',
    unlockCondition: 'Usa el metro 7 días consecutivos',
    rarity: 'rare',
    unlocked: true
  },
  {
    id: 'congos',
    name: 'Congos',
    icon: '🎭',
    category: 'culture',
    description: 'Celebración Cultural',
    culturalInfo: 'Cultura afrocolonial de la costa atlántica. Representa la diversidad cultural panameña.',
    unlockCondition: 'Reporta eventos positivos en 10 estaciones diferentes',
    rarity: 'epic',
    unlocked: false
  },
  {
    id: 'mojadera',
    name: 'Mojadera',
    icon: '🌊',
    category: 'culture',
    description: 'Flujo Como el Mar',
    culturalInfo: 'Baile de la costa que imita el movimiento del mar. Representa el flujo suave de tus viajes.',
    unlockCondition: 'Completa 15 transbordos perfectos',
    rarity: 'rare',
    unlocked: false
  },

  // Héroes
  {
    id: 'urraca',
    name: 'Urracá',
    icon: '🛶',
    category: 'hero',
    description: 'Perseverancia',
    culturalInfo: 'Cacique que resistió la conquista española. Símbolo de fuerza y perseverancia del pueblo panameño.',
    unlockCondition: 'Alcanza nivel máximo de usuario',
    rarity: 'legendary',
    unlocked: false,
    featured: true
  },
  {
    id: 'victoriano',
    name: 'Victoriano Lorenzo',
    icon: '⚔️',
    category: 'hero',
    description: 'Héroe del Pueblo',
    culturalInfo: 'Héroe popular de la Guerra de los Mil Días. Luchó por los derechos del pueblo panameño.',
    unlockCondition: 'Ayuda a 100 usuarios con reportes útiles',
    rarity: 'legendary',
    unlocked: false
  },
  {
    id: 'amador',
    name: 'Manuel Amador Guerrero',
    icon: '🎓',
    category: 'hero',
    description: 'Liderazgo',
    culturalInfo: 'Primer presidente de la República de Panamá. Líder de la independencia.',
    unlockCondition: 'Alcanza el nivel de "Líder Comunitario"',
    rarity: 'epic',
    unlocked: false
  },
  {
    id: 'torrijos',
    name: 'Omar Torrijos',
    icon: '🌎',
    category: 'hero',
    description: 'Logro Histórico',
    culturalInfo: 'Líder de la recuperación del Canal de Panamá. Figura clave en la historia moderna del país.',
    unlockCondition: 'Usa MetroPTY durante 1 año completo',
    rarity: 'legendary',
    unlocked: false
  },

  // Arquitectura
  {
    id: 'puente-americas',
    name: 'Puente de las Américas',
    icon: '🌉',
    category: 'architecture',
    description: 'Conexión Continental',
    culturalInfo: 'Icónico puente que une América del Norte y del Sur. Símbolo de conexión y unión.',
    unlockCondition: 'Conecta con 50 usuarios diferentes',
    rarity: 'epic',
    unlocked: true
  },
  {
    id: 'canal',
    name: 'Canal de Panamá',
    icon: '🚢',
    category: 'architecture',
    description: 'Eficiencia Máxima',
    culturalInfo: 'Una de las maravillas de la ingeniería moderna. Las esclusas de Miraflores, Gatún y Pedro Miguel son íconos mundiales.',
    unlockCondition: 'Optimiza tus rutas 25 veces',
    rarity: 'legendary',
    unlocked: true,
    featured: true
  },
  {
    id: 'casco-antiguo',
    name: 'Casco Antiguo',
    icon: '🏰',
    category: 'architecture',
    description: 'Patrimonio Clásico',
    culturalInfo: 'Centro histórico colonial de Ciudad de Panamá, Patrimonio de la Humanidad. Sus arcos, balcones y plazas cuentan siglos de historia.',
    unlockCondition: 'Visita 10 estaciones del centro histórico',
    rarity: 'rare',
    unlocked: false
  },
  {
    id: 'volcan-baru',
    name: 'Volcán Barú',
    icon: '🌋',
    category: 'architecture',
    description: 'La Cumbre',
    culturalInfo: 'Punto más alto de Panamá (3,475 m). Desde su cima se pueden ver ambos océanos.',
    unlockCondition: 'Alcanza el nivel más alto en todos los logros',
    rarity: 'legendary',
    unlocked: false
  },
  {
    id: 'san-blas',
    name: 'San Blas',
    icon: '🏝️',
    category: 'architecture',
    description: 'Cultura Única',
    culturalInfo: 'Archipiélago de Guna Yala, hogar de la cultura Guna y sus famosas molas (arte textil). Paraíso caribeño único.',
    unlockCondition: 'Colecciona 15 logros de diferentes categorías',
    rarity: 'epic',
    unlocked: false
  },

  // Naturaleza
  {
    id: 'palma-real',
    name: 'Palma Real',
    icon: '🌴',
    category: 'nature',
    description: 'Crecimiento Constante',
    culturalInfo: 'Símbolo tropical de Panamá. Representa crecimiento y desarrollo constante.',
    unlockCondition: 'Sube de nivel 5 veces',
    rarity: 'common',
    unlocked: true
  },
  {
    id: 'espiritu-santo',
    name: 'Orquídea Espíritu Santo',
    icon: '🌺',
    category: 'nature',
    description: 'Flor Nacional',
    culturalInfo: 'Flor nacional de Panamá (Peristeria elata). Su forma interior parece una paloma blanca.',
    unlockCondition: 'Completa un logro especial mensual',
    rarity: 'legendary',
    unlocked: false
  },
  {
    id: 'arbol-panama',
    name: 'Árbol de Panamá',
    icon: '🌳',
    category: 'nature',
    description: 'Raíces Fundacionales',
    culturalInfo: 'Árbol que da nombre al país. Sus flores amarillas iluminan el paisaje tropical.',
    unlockCondition: 'Completa tu primera semana en MetroPTY',
    rarity: 'rare',
    unlocked: true
  },
  {
    id: 'darien',
    name: 'Darién',
    icon: '🏞️',
    category: 'nature',
    description: 'Explorador Intrépido',
    culturalInfo: 'Selva impenetrable, una de las regiones más biodiversas del planeta. Representa los retos más difíciles.',
    unlockCondition: 'Supera 10 situaciones complicadas',
    rarity: 'epic',
    unlocked: false
  },

  // Festividades
  {
    id: 'carnavales',
    name: 'Carnavales',
    icon: '🎉',
    category: 'festival',
    description: 'Fiesta Nacional',
    culturalInfo: 'Los Carnavales de Panamá son famosos por sus reinas, culecos y carrozas. Cuatro días de celebración nacional.',
    unlockCondition: 'Gana puntos dobles durante carnavales',
    rarity: 'epic',
    unlocked: false
  },
  {
    id: 'feria-david',
    name: 'Feria de David',
    icon: '🎪',
    category: 'festival',
    description: 'Tradición Interiorana',
    culturalInfo: 'Feria Internacional de David en Chiriquí. Celebración de la cultura del interior del país.',
    unlockCondition: 'Participa en eventos regionales',
    rarity: 'rare',
    unlocked: false
  },
  {
    id: 'mejorana',
    name: 'Festival de la Mejorana',
    icon: '🎵',
    category: 'festival',
    description: 'Música Tradicional',
    culturalInfo: 'Festival de música típica en Guararé. Celebración de la música folclórica panameña.',
    unlockCondition: 'Completa logros musicales y de ritmo',
    rarity: 'rare',
    unlocked: false
  },
];
