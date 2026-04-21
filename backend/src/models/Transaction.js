const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  return sequelize.define(
    'Transaction',
    {
      id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
      asset: { type: DataTypes.STRING, allowNull: false },
      amount: { type: DataTypes.DECIMAL(20, 8), allowNull: false },
      usdEquivalent: { type: DataTypes.DECIMAL(20, 2), allowNull: false },
      type: {
        type: DataTypes.ENUM('deposit', 'withdrawal', 'trade', 'fee'),
        allowNull: false
      },
      status: {
        type: DataTypes.ENUM('pending', 'completed', 'failed'),
        allowNull: false,
        defaultValue: 'pending'
      },
      notes: { type: DataTypes.TEXT, allowNull: true }
    },
    { tableName: 'transactions', timestamps: true }
  );
};
