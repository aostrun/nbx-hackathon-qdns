module.exports = {
    domainBuy: (req, res) => {
        res.render('users/buy')
    },
    domainPrice: (req, res) => {
        res.render('users/price')
    },
    domainAddress: (req, res) => {
        res.render('users/getaddress')
    },
    domainInfo: (req, res) => {
        res.render('users/getinfo')
    },
    domainRenew: (req, res) => {
        res.render('users/renew', {domainName: req.query.domainName})
    },
    domainEdit: (req, res) => {
        res.render('users/edit', {domainName: req.query.domainName})
    },
    domainTransfer: (req, res) => {
        res.render('users/transfer', {domainName: req.query.domainName})
    }
}