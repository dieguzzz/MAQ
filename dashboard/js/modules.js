// Modules Documentation Tab - Search and Filter functionality

function filterModules(query) {
  const cards = document.querySelectorAll('#modulesContainer .module-card');
  const lowerQuery = query.toLowerCase().trim();

  cards.forEach(card => {
    if (!lowerQuery) {
      card.style.display = '';
      return;
    }

    const title = card.querySelector('h3')?.textContent.toLowerCase() || '';
    const description = card.querySelector('.module-description')?.textContent.toLowerCase() || '';
    const keywords = (card.getAttribute('data-keywords') || '').toLowerCase();
    const path = card.querySelector('.module-path')?.textContent.toLowerCase() || '';

    const matches = title.includes(lowerQuery) ||
                    description.includes(lowerQuery) ||
                    keywords.includes(lowerQuery) ||
                    path.includes(lowerQuery);

    card.style.display = matches ? '' : 'none';
  });
}

function filterModuleCategory(category, btn) {
  // Update active button
  document.querySelectorAll('.module-filter-btn').forEach(b => b.classList.remove('active'));
  if (btn) btn.classList.add('active');

  // Clear search
  const searchInput = document.getElementById('modulesSearch');
  if (searchInput) searchInput.value = '';

  const cards = document.querySelectorAll('#modulesContainer .module-card');

  cards.forEach(card => {
    if (category === 'all') {
      card.style.display = '';
    } else {
      const cardCategory = card.getAttribute('data-category');
      card.style.display = cardCategory === category ? '' : 'none';
    }
  });
}

// Export for global use
window.filterModules = filterModules;
window.filterModuleCategory = filterModuleCategory;
