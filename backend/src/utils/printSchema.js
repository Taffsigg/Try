const { sequelize } = require('../models');

(async () => {
  const queryInterface = sequelize.getQueryInterface();
  const tables = await queryInterface.showAllTables();
  console.log('Tables:', tables);
  process.exit(0);
})();
