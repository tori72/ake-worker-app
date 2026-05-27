// src/routes/transactions.js
// POST /api/transactions  — create a sales transaction
// GET  /api/transactions  — list transactions (with pagination)

const express = require('express');
const router = express.Router();
const { body, query, validationResult } = require('express-validator');
const supabase = require('../config/supabase');
const { asyncHandler } = require('../middleware/errorHandler');

// ─────────────────────────────────────────────
// Validation rules
// ─────────────────────────────────────────────

const VALID_UOM  = ['5', 'Gross', 'KH', 'Pcs', 'Box'];
const VALID_MODE = ['cash', 'online', 'credit-slip', 'gst-cash', 'gst-bank', 'gst-credit'];

const transactionValidationRules = [
  body('date')
    .isISO8601().withMessage('date must be a valid ISO date (YYYY-MM-DD)'),
  body('party')
    .trim().notEmpty().withMessage('party is required'),
  body('item_id')
    .isInt({ min: 1 }).withMessage('item_id must be a positive integer'),
  body('thread_id')
    .isInt({ min: 1 }).withMessage('thread_id must be a positive integer'),
  body('length_id')
    .isInt({ min: 1 }).withMessage('length_id must be a positive integer'),
  body('head_id')
    .isInt({ min: 1 }).withMessage('head_id must be a positive integer'),
  body('colour_id')
    .isInt({ min: 1 }).withMessage('colour_id must be a positive integer'),
  body('quantity')
    .isInt({ min: 1 }).withMessage('quantity must be a positive integer'),
  body('uom')
    .isIn(VALID_UOM).withMessage(`uom must be one of: ${VALID_UOM.join(', ')}`),
  body('rate')
    .isFloat({ min: 0 }).withMessage('rate must be a non-negative number'),
  body('mode')
    .isIn(VALID_MODE).withMessage(`mode must be one of: ${VALID_MODE.join(', ')}`),
];

// ─────────────────────────────────────────────
// POST /api/transactions
// ─────────────────────────────────────────────

router.post(
  '/',
  transactionValidationRules,
  asyncHandler(async (req, res) => {
    // 1. Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(422).json({
        success: false,
        error: 'Validation failed',
        details: errors.array(),
      });
    }

    const {
      date, party,
      item_id, thread_id, length_id, head_id, colour_id,
      quantity, uom, rate, mode,
    } = req.body;

    // 2. Insert into Supabase (amount is a generated column — do not pass it)
    const { data, error } = await supabase
      .from('sales_transactions')
      .insert([{
        date,
        party,
        item_id,
        thread_id,
        length_id,
        head_id,
        colour_id,
        quantity,
        uom,
        rate,
        mode,
      }])
      .select()
      .single();

    if (error) {
      const err = new Error(`Failed to save transaction: ${error.message}`);
      err.status = 502;
      throw err;
    }

    res.status(201).json({ success: true, data });
  })
);

// ─────────────────────────────────────────────
// GET /api/transactions?page=1&limit=20
// ─────────────────────────────────────────────

router.get(
  '/',
  [
    query('page').optional().isInt({ min: 1 }).toInt(),
    query('limit').optional().isInt({ min: 1, max: 100 }).toInt(),
  ],
  asyncHandler(async (req, res) => {
    const page  = req.query.page  || 1;
    const limit = req.query.limit || 20;
    const from  = (page - 1) * limit;
    const to    = from + limit - 1;

    const { data, error, count } = await supabase
      .from('sales_transactions')
      .select(
        `id, date, party, quantity, uom, rate, amount, mode, created_at,
         items(name), threads(name), lengths(value), heads(name), colours(name)`,
        { count: 'exact' }
      )
      .order('created_at', { ascending: false })
      .range(from, to);

    if (error) {
      const err = new Error(`Failed to fetch transactions: ${error.message}`);
      err.status = 502;
      throw err;
    }

    res.json({
      success: true,
      data,
      meta: {
        total: count,
        page,
        limit,
        totalPages: Math.ceil(count / limit),
      },
    });
  })
);

// ─────────────────────────────────────────────
// GET /api/transactions/:id
// ─────────────────────────────────────────────

router.get(
  '/:id',
  asyncHandler(async (req, res) => {
    const { data, error } = await supabase
      .from('sales_transactions')
      .select(
        `*, items(name), threads(name), lengths(value), heads(name), colours(name)`
      )
      .eq('id', req.params.id)
      .single();

    if (error || !data) {
      return res.status(404).json({ success: false, error: 'Transaction not found' });
    }

    res.json({ success: true, data });
  })
);

module.exports = router;
