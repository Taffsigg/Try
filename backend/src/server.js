const app = require('./app');
const { sequelize } = require('./models');
const { seedDefaultUsers } = require('./utils/seedAdmin');

const PORT = Number(process.env.PORT || 4000);

async function start() {
  try {
    await sequelize.authenticate();
    await sequelize.sync();
    await seedDefaultUsers();

    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error.message);
    process.exit(1);
  }
}

start();
