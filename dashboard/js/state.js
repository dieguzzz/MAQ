// Estado global del dashboard (sin frameworks)
(function () {
  window.Dashboard = window.Dashboard || {};

  window.Dashboard.state = {
    isAuthenticated: false,
    currentUser: null,
    refreshInterval: null,
    authInitialized: false,

    statsCache: {
      users: 0,
      reports: 0,
      stations: 0,
      trains: 0,
    },

    logsUnsubscribe: null,
    allLogs: [],
  };
})();


