"use strict";
require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY); // Make sure this is set

const app = express();
const PORT = 3000;

app.use(bodyParser.json());

// Health check route (optional)
app.get('/', (req, res) => {
  res.send('Stripe backend is running.');
});

app.post('/create-payment-intent', async (req, res) => {
  const { amount, currency } = req.body;

  console.log('Received request with amount:', amount, 'currency:', currency);

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount, // must be an integer, in cents for most currencies
      currency: currency,
      payment_method_types: ['card'], // explicitly specify card
    });

    console.log('PaymentIntent created:', paymentIntent.id);
    res.json({ clientSecret: paymentIntent.client_secret });
  } catch (e) {
    console.error('Error creating PaymentIntent:', e.message);
    res.status(400).send({ error: e.message });
  }
});

app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});
