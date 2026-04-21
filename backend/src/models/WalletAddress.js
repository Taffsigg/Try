const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  return sequelize.define(
    'WalletAddress',
    {
      id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
      label: { type: DataTypes.STRING, allowNull: true },
      address: { type: DataTypes.STRING, allowNull: false }
    },
    { tableName: 'wallet_addresses', timestamps: true }
  );
};
