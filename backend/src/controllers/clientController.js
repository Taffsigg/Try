const { Client, WalletAddress, Transaction } = require('../models');
const { logAudit } = require('../services/auditService');

async function createClient(req, res) {
  const { name, email, companyInfo, walletAddresses = [] } = req.body;
  const client = await Client.create({ name, email, companyInfo });

  if (walletAddresses.length) {
    await WalletAddress.bulkCreate(
      walletAddresses.map((wallet) => ({
        clientId: client.id,
        label: wallet.label,
        address: wallet.address
      }))
    );
  }

  await logAudit({
    userId: req.user.id,
    action: 'CREATE_CLIENT',
    entity: 'client',
    entityId: client.id,
    changes: req.body
  });

  const result = await Client.findByPk(client.id, { include: [{ model: WalletAddress, as: 'walletAddresses' }] });
  return res.status(201).json(result);
}

async function getClients(req, res) {
  const clients = await Client.findAll({
    include: [{ model: WalletAddress, as: 'walletAddresses' }],
    order: [['createdAt', 'DESC']]
  });
  return res.json(clients);
}

async function getClientById(req, res) {
  const client = await Client.findByPk(req.params.id, {
    include: [
      { model: WalletAddress, as: 'walletAddresses' },
      { model: Transaction, as: 'transactions', limit: 50, separate: true, order: [['createdAt', 'DESC']] }
    ]
  });
  if (!client) return res.status(404).json({ message: 'Client not found' });
  return res.json(client);
}

async function updateClient(req, res) {
  const client = await Client.findByPk(req.params.id);
  if (!client) return res.status(404).json({ message: 'Client not found' });

  const before = client.toJSON();
  const { name, email, companyInfo, walletAddresses } = req.body;
  await client.update({ name, email, companyInfo });

  if (Array.isArray(walletAddresses)) {
    await WalletAddress.destroy({ where: { clientId: client.id } });
    if (walletAddresses.length) {
      await WalletAddress.bulkCreate(
        walletAddresses.map((wallet) => ({ clientId: client.id, label: wallet.label, address: wallet.address }))
      );
    }
  }

  await logAudit({
    userId: req.user.id,
    action: 'UPDATE_CLIENT',
    entity: 'client',
    entityId: client.id,
    changes: { before, after: req.body }
  });

  const result = await Client.findByPk(client.id, { include: [{ model: WalletAddress, as: 'walletAddresses' }] });
  return res.json(result);
}

async function deleteClient(req, res) {
  const client = await Client.findByPk(req.params.id);
  if (!client) return res.status(404).json({ message: 'Client not found' });
  await client.destroy();

  await logAudit({
    userId: req.user.id,
    action: 'DELETE_CLIENT',
    entity: 'client',
    entityId: req.params.id,
    changes: null
  });

  return res.json({ message: 'Client deleted successfully' });
}

module.exports = { createClient, getClients, getClientById, updateClient, deleteClient };
