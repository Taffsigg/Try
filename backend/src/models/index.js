const sequelize = require('../config/database');

const User = require('./User')(sequelize);
const Client = require('./Client')(sequelize);
const WalletAddress = require('./WalletAddress')(sequelize);
const Transaction = require('./Transaction')(sequelize);
const LedgerEntry = require('./LedgerEntry')(sequelize);
const AuditLog = require('./AuditLog')(sequelize);

Client.hasMany(WalletAddress, { foreignKey: 'clientId', as: 'walletAddresses', onDelete: 'CASCADE' });
WalletAddress.belongsTo(Client, { foreignKey: 'clientId' });

Client.hasMany(Transaction, { foreignKey: 'clientId', as: 'transactions', onDelete: 'CASCADE' });
Transaction.belongsTo(Client, { foreignKey: 'clientId', as: 'client' });

Client.hasMany(LedgerEntry, { foreignKey: 'clientId', as: 'ledgerEntries', onDelete: 'CASCADE' });
LedgerEntry.belongsTo(Client, { foreignKey: 'clientId', as: 'client' });

Transaction.hasOne(LedgerEntry, { foreignKey: 'transactionId', as: 'ledgerEntry', onDelete: 'CASCADE' });
LedgerEntry.belongsTo(Transaction, { foreignKey: 'transactionId', as: 'transaction' });

User.hasMany(AuditLog, { foreignKey: 'userId', as: 'auditLogs' });
AuditLog.belongsTo(User, { foreignKey: 'userId', as: 'user' });

module.exports = {
  sequelize,
  User,
  Client,
  WalletAddress,
  Transaction,
  LedgerEntry,
  AuditLog
};
