const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  return sequelize.define(
    'LedgerEntry',
    {
      id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
      transactionId: { type: DataTypes.INTEGER, allowNull: false, unique: true },
      asset: { type: DataTypes.STRING, allowNull: false },
      amount: { type: DataTypes.DECIMAL(20, 8), allowNull: false },
      usdValue: { type: DataTypes.DECIMAL(20, 2), allowNull: false },
      status: {
        type: DataTypes.ENUM('pending', 'completed', 'failed'),
        allowNull: false
      },
      timestamp: { type: DataTypes.DATE, allowNull: false }
    },
    { tableName: 'ledger_entries', timestamps: true }
  );
};
