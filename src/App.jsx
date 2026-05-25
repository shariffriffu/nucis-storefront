import React, { useState, useEffect, useMemo } from 'react';
import { 
  ShoppingBag, 
  Heart, 
  User, 
  Settings, 
  TrendingUp, 
  ShieldCheck, 
  Search, 
  SlidersHorizontal, 
  ChevronRight, 
  Star, 
  Trash2, 
  CreditCard, 
  Cpu, 
  Layers, 
  ArrowLeft,
  ChevronDown, 
  Plus, 
  Sparkles, 
  CheckCircle, 
  X,
  Package,
  Calendar,
  Lock,
  ArrowRight,
  Sun,
  Moon,
  Menu,
  MessageSquare
} from 'lucide-react';
import { AnimatePresence, motion } from 'framer-motion';

// Mock data & helper imports
import { products as initialProducts, reviews, blogs, faqs, coupons } from './data/products';
import AWSVisualizer from './components/AWSVisualizer';
import Chatbot from './components/Chatbot';

export default function App() {
  // Navigation & Theme
  const [activePage, setActivePage] = useState('home'); // home, shop, details, checkout, dashboard, admin, vendor, aws
  const [selectedProductId, setSelectedProductId] = useState('almonds-premium');
  const [isDark, setIsDark] = useState(true);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  // Shop state & filters
  const [productsList, setProductsList] = useState(initialProducts);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('All');
  const [priceRange, setPriceRange] = useState(3000);
  const [selectedWeightFilter, setSelectedWeightFilter] = useState('All');
  const [sortBy, setSortBy] = useState('popular');
  const [viewMode, setViewMode] = useState('grid'); // grid / list
  const [stockOnly, setStockOnly] = useState(false);

  // Cart & Wishlist state
  const [cart, setCart] = useState([]);
  const [wishlist, setWishlist] = useState([]);
  const [isCartOpen, setIsCartOpen] = useState(false);
  const [couponCode, setCouponCode] = useState('');
  const [appliedCoupon, setAppliedCoupon] = useState(null);
  
  // Checkout & Shipping
  const [checkoutStep, setCheckoutStep] = useState(1); // 1: Shipping Address, 2: Payment Selector
  const [selectedAddressIndex, setSelectedAddressIndex] = useState(0);
  const [addresses, setAddresses] = useState([
    { id: 1, type: 'Home', name: 'Shariff Ahmed', phone: '+91 98765 43210', address: 'Flat 402, Royal Residency, Palace Road', city: 'Bangalore', state: 'Karnataka', pincode: '560001' },
    { id: 2, type: 'Office', name: 'Shariff Ahmed (Business)', phone: '+91 98765 99999', address: 'Plot 12, Tech Park Central, Outer Ring Road', city: 'Bangalore', state: 'Karnataka', pincode: '560103' }
  ]);
  const [newAddress, setNewAddress] = useState({ type: 'Home', name: '', phone: '', address: '', city: '', state: '', pincode: '' });
  const [showAddressForm, setShowAddressForm] = useState(false);
  const [paymentMethod, setPaymentMethod] = useState('upi'); // upi, card, cod
  const [isProcessingPayment, setIsProcessingPayment] = useState(false);
  const [isPaymentSuccess, setIsPaymentSuccess] = useState(false);
  const [recentOrderDetails, setRecentOrderDetails] = useState(null);

  // User details, Rewards, & Orders
  const [userOrders, setUserOrders] = useState([
    {
      id: 'ORD-98231',
      date: 'May 20, 2026',
      items: [
        { id: 'almonds-premium', name: 'Premium California Almonds', quantity: 2, weight: '500g', price: 749 }
      ],
      amount: 1498,
      status: 'Delivered',
      deliveryDate: 'May 22, 2026',
      trackingStep: 4, // 1: Ordered, 2: Packed, 3: Out for Delivery, 4: Delivered
      invoiceNo: 'INV-2026-98231'
    },
    {
      id: 'ORD-77621',
      date: 'May 24, 2026',
      items: [
        { id: 'cashews-royal', name: 'Royal Mangalore Cashews', quantity: 1, weight: '250g', price: 499 },
        { id: 'seeds-superfood', name: 'Premium 7-in-1 Omega Seed Mix', quantity: 1, weight: '500g', price: 549 }
      ],
      amount: 1048,
      status: 'Packed',
      deliveryDate: 'May 27, 2026',
      trackingStep: 2,
      invoiceNo: 'INV-2026-77621'
    }
  ]);
  const [userSubscriptions, setUserSubscriptions] = useState([
    { id: 'SUB-441', name: 'Daily Almond Brain Vitality Pack', frequency: 'Monthly', weight: '1kg', price: 1399, nextDate: 'June 10, 2026', status: 'Active' },
    { id: 'SUB-229', name: 'Healthy Heart Seed Supply', frequency: 'Weekly', weight: '500g', price: 549, nextDate: 'June 02, 2026', status: 'Active' }
  ]);
  const [userPoints, setUserPoints] = useState(450); // Loyalty rewards points

  // Vendor State
  const [vendorProducts, setVendorProducts] = useState([
    { id: 'V-101', name: 'Organic Afghan Dried Figs (Anjeer)', price: 799, status: 'Pending Approval', quantity: '50kg', date: 'May 24, 2026' },
    { id: 'V-102', name: 'Turkish Salted Hazelnuts', price: 649, status: 'Approved & Active', quantity: '80kg', date: 'May 20, 2026' }
  ]);
  const [vendorSettlements, setVendorSettlements] = useState([
    { id: 'SET-992', date: 'May 15, 2026', amount: 24500, status: 'Settled' },
    { id: 'SET-881', date: 'May 22, 2026', amount: 18750, status: 'Processing' }
  ]);

  // Product Details Page interactive weight & gallery state
  const [selectedDetailWeight, setSelectedDetailWeight] = useState('250g');
  const [selectedDetailImageIndex, setSelectedDetailImageIndex] = useState(0);
  const [rotationDegrees, setRotationDegrees] = useState(0); // 3D box model simulation
  const [pincodeCheck, setPincodeCheck] = useState('');
  const [pincodeMessage, setPincodeMessage] = useState(null);

  // Active product details item
  const selectedProduct = useMemo(() => {
    return productsList.find(p => p.id === selectedProductId) || productsList[0];
  }, [productsList, selectedProductId]);

  // Fetch Live Products from Backend
  useEffect(() => {
    const fetchLiveProducts = async () => {
      try {
        const response = await fetch('http://13.207.1.144:5000/api/products');
        const json = await response.json();
        if (json.success && json.data) {
          setProductsList(json.data);
        }
      } catch (err) {
        console.error('Failed to load products from server, using offline fallback:', err);
      }
    };
    fetchLiveProducts();
  }, []);

  // Toggle Dark/Light Mode on HTML body directly
  useEffect(() => {
    const root = window.document.documentElement;
    const body = window.document.body;
    if (isDark) {
      root.classList.add('dark');
      body.style.backgroundColor = '#09100d';
      body.style.color = '#e2eae6';
    } else {
      root.classList.remove('dark');
      body.style.backgroundColor = '#f4f7f6';
      body.style.color = '#233932';
    }
  }, [isDark]);

  // Filtered Products
  const filteredProducts = useMemo(() => {
    let result = [...productsList];

    // Search filter
    if (searchTerm.trim() !== '') {
      result = result.filter(p => p.name.toLowerCase().includes(searchTerm.toLowerCase()));
    }

    // Category filter
    if (selectedCategory !== 'All') {
      result = result.filter(p => p.category === selectedCategory);
    }

    // Price filter
    result = result.filter(p => p.price <= priceRange);

    // Stock status filter
    if (stockOnly) {
      result = result.filter(p => p.inStock > 0);
    }

    // Sort order
    if (sortBy === 'price-low') {
      result.sort((a, b) => a.price - b.price);
    } else if (sortBy === 'price-high') {
      result.sort((a, b) => b.price - a.price);
    } else if (sortBy === 'rating') {
      result.sort((a, b) => b.rating - a.rating);
    }

    return result;
  }, [productsList, searchTerm, selectedCategory, priceRange, stockOnly, sortBy]);

  // Cart calculations
  const cartSubtotal = useMemo(() => {
    return cart.reduce((sum, item) => {
      // Calculate price multiplier based on weight selector
      let multiplier = 1;
      if (item.weight === '500g') multiplier = 1.9; // 10% discount for 500g
      if (item.weight === '1kg') multiplier = 3.5;  // 15% discount for 1kg
      return sum + Math.round(item.product.price * multiplier) * item.quantity;
    }, 0);
  }, [cart]);

  const discountAmount = useMemo(() => {
    if (!appliedCoupon) return 0;
    if (cartSubtotal < appliedCoupon.minAmount) return 0;
    return Math.round((cartSubtotal * appliedCoupon.discount) / 100);
  }, [appliedCoupon, cartSubtotal]);

  const gstAmount = useMemo(() => {
    // 5% GST on organic food/nuts in India
    return Math.round((cartSubtotal - discountAmount) * 0.05);
  }, [cartSubtotal, discountAmount]);

  const deliveryCharge = useMemo(() => {
    if (cartSubtotal - discountAmount > 999 || cartSubtotal === 0) return 0; // Free delivery above ₹999
    return 80;
  }, [cartSubtotal, discountAmount]);

  const cartTotal = useMemo(() => {
    return Math.max(0, cartSubtotal - discountAmount + gstAmount + deliveryCharge);
  }, [cartSubtotal, discountAmount, gstAmount, deliveryCharge]);

  // Unified Cart handlers
  const handleAddToCart = (productKey, weight = '250g', qty = 1) => {
    const prod = productsList.find(p => p.id === productKey);
    if (!prod) return;

    setCart(prev => {
      const existingIdx = prev.findIndex(item => item.product.id === productKey && item.weight === weight);
      if (existingIdx > -1) {
        const updated = [...prev];
        updated[existingIdx].quantity += qty;
        return updated;
      } else {
        return [...prev, { product: prod, weight, quantity: qty }];
      }
    });

    setIsCartOpen(true);
  };

  const handleUpdateCartQty = (productKey, weight, newQty) => {
    if (newQty <= 0) {
      setCart(prev => prev.filter(item => !(item.product.id === productKey && item.weight === weight)));
      return;
    }
    setCart(prev => {
      return prev.map(item => {
        if (item.product.id === productKey && item.weight === weight) {
          return { ...item, quantity: newQty };
        }
        return item;
      });
    });
  };

  const handleToggleWishlist = (productId) => {
    setWishlist(prev => {
      if (prev.includes(productId)) {
        return prev.filter(id => id !== productId);
      } else {
        return [...prev, productId];
      }
    });
  };

  const handleApplyCoupon = () => {
    const found = coupons.find(c => c.code.toUpperCase() === couponCode.toUpperCase());
    if (found) {
      if (cartSubtotal >= found.minAmount) {
        setAppliedCoupon(found);
      } else {
        alert(`Minimum order of ₹${found.minAmount} is required for this coupon.`);
      }
    } else {
      alert('Invalid Promo Code.');
    }
  };

  // Pincode Checker Simulation
  const handleCheckPincode = (e) => {
    e.preventDefault();
    if (!pincodeCheck.trim() || pincodeCheck.length !== 6) {
      setPincodeMessage({ type: 'error', text: 'Please enter a valid 6-digit PIN.' });
      return;
    }
    setPincodeMessage({ 
      type: 'success', 
      text: `🌿 Deliverable! Sourced fresh and delivered by tomorrow, 6:00 PM via Nucis Gold Express.` 
    });
  };

  // Add Address Form
  const handleAddAddress = (e) => {
    e.preventDefault();
    setAddresses(prev => [...prev, { id: Date.now(), ...newAddress }]);
    setNewAddress({ type: 'Home', name: '', phone: '', address: '', city: '', state: '', pincode: '' });
    setShowAddressForm(false);
  };

  // Checkout process connecting to live Express guest checkout
  const handleCompleteOrder = async () => {
    setIsProcessingPayment(true);

    const cartItems = cart.map(item => ({
      id: item.product.id,
      quantity: item.quantity,
      price: item.product.price,
      weight: item.weight
    }));

    try {
      const response = await fetch('http://13.207.1.144:5000/api/orders/guest', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          customerName: addresses[selectedAddressIndex]?.name || 'Guest Customer',
          totalAmount: cartTotal,
          cartItems: cartItems
        })
      });

      const json = await response.json();
      if (!response.ok || !json.success) {
        throw new Error(json.message || 'Server error processing order');
      }

      // Deduct mock inventory stock in real-time
      setProductsList(prev => {
        return prev.map(p => {
          const cartItem = cart.find(c => c.product.id === p.id);
          if (cartItem) {
            return { ...p, inStock: Math.max(0, p.inStock - cartItem.quantity) };
          }
          return p;
        });
      });

      const backendOrder = json.data;

      // Assemble new completed order
      const newOrder = {
        id: backendOrder.orderNumber || `ORD-${Math.floor(10000 + Math.random() * 90000)}`,
        date: new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
        items: cart.map(item => {
          let multiplier = 1;
          if (item.weight === '500g') multiplier = 1.9;
          if (item.weight === '1kg') multiplier = 3.5;
          return {
            id: item.product.id,
            name: item.product.name,
            quantity: item.quantity,
            weight: item.weight,
            price: Math.round(item.product.price * multiplier)
          };
        }),
        amount: cartTotal,
        status: 'Confirmed',
        deliveryDate: new Date(Date.now() + 48*60*60*1000).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
        trackingStep: 1,
        invoiceNo: `INV-2026-${Math.floor(10000 + Math.random() * 90000)}`
      };

      // Add to loyalty points (₹100 = 10 points)
      setUserPoints(prev => prev + Math.round(cartTotal / 10));

      setUserOrders(prev => [newOrder, ...prev]);
      setRecentOrderDetails(newOrder);
      setIsProcessingPayment(false);
      setIsPaymentSuccess(true);
      setCart([]); // Clear Cart
    } catch (err) {
      console.error('Failed to submit order to live backend, falling back to simulated order:', err);
      // Fallback checkout logic
      setTimeout(() => {
        setProductsList(prev => {
          return prev.map(p => {
            const cartItem = cart.find(c => c.product.id === p.id);
            if (cartItem) {
              return { ...p, inStock: Math.max(0, p.inStock - cartItem.quantity) };
            }
            return p;
          });
        });

        const newOrder = {
          id: `ORD-${Math.floor(10000 + Math.random() * 90000)}`,
          date: new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
          items: cart.map(item => {
            let multiplier = 1;
            if (item.weight === '500g') multiplier = 1.9;
            if (item.weight === '1kg') multiplier = 3.5;
            return {
              id: item.product.id,
              name: item.product.name,
              quantity: item.quantity,
              weight: item.weight,
              price: Math.round(item.product.price * multiplier)
            };
          }),
          amount: cartTotal,
          status: 'Confirmed',
          deliveryDate: new Date(Date.now() + 48*60*60*1000).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
          trackingStep: 1,
          invoiceNo: `INV-2026-${Math.floor(10000 + Math.random() * 90000)}`
        };

        setUserPoints(prev => prev + Math.round(cartTotal / 10));
        setUserOrders(prev => [newOrder, ...prev]);
        setRecentOrderDetails(newOrder);
        setIsProcessingPayment(false);
        setIsPaymentSuccess(true);
        setCart([]); // Clear Cart
      }, 1500);
    }
  };

  return (
    <div className={`min-h-screen transition-colors duration-300 font-sans relative ${
      isDark ? 'bg-[#09100d] text-gray-100' : 'bg-[#f4f7f6] text-gray-800'
    }`}>
      
      {/* Background radial glow */}
      {isDark && (
        <div className="absolute top-0 left-0 w-full h-[500px] bg-gradient-radial from-luxuryGreen-950/40 via-transparent to-transparent pointer-events-none z-0" />
      )}

      {/* Floating Chatbot Assistant */}
      <Chatbot onAddToCart={handleAddToCart} />

      {/* Cart Drawer */}
      <AnimatePresence>
        {isCartOpen && (
          <>
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 0.5 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsCartOpen(false)}
              className="fixed inset-0 bg-black z-45"
            />
            <motion.div 
              initial={{ x: '100%' }}
              animate={{ x: 0 }}
              exit={{ x: '100%' }}
              transition={{ type: 'spring', damping: 25, stiffness: 200 }}
              className={`fixed right-0 top-0 bottom-0 w-full md:w-[450px] z-50 shadow-2xl flex flex-col p-6 border-l ${
                isDark ? 'bg-[#0b1310] border-luxuryGreen-900' : 'bg-white border-gray-200 text-gray-800'
              }`}
            >
              {/* Header */}
              <div className="flex justify-between items-center mb-6 pb-4 border-b border-luxuryGreen-950/60">
                <div className="flex items-center gap-2">
                  <ShoppingBag className="text-luxuryGold-500" size={24} />
                  <h3 className={`text-lg font-bold ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>Your Luxury Basket</h3>
                </div>
                <button 
                  onClick={() => setIsCartOpen(false)}
                  className={`p-1.5 rounded-full transition-colors ${
                    isDark ? 'hover:bg-luxuryGreen-950/40 text-gray-400 hover:text-white' : 'hover:bg-gray-100 text-gray-500 hover:text-gray-800'
                  }`}
                >
                  <X size={20} />
                </button>
              </div>

              {/* Items List */}
              <div className="flex-1 overflow-y-auto space-y-4 pr-1 scrollbar-none">
                {cart.length === 0 ? (
                  <div className="flex flex-col items-center justify-center h-full text-center py-12">
                    <ShoppingBag size={48} className="text-luxuryGreen-850 animate-bounce mb-3" />
                    <p className="text-sm font-medium">Your basket is currently empty.</p>
                    <p className="text-xs text-gray-500 mt-1">Explore our premium raw badam and corporate gift hampers.</p>
                    <button 
                      onClick={() => { setIsCartOpen(false); setActivePage('shop'); }}
                      className="mt-4 text-xs font-mono text-luxuryGold-600 hover:text-luxuryGold-500 flex items-center gap-1"
                    >
                      Browse Wellness Shop <ChevronRight size={14} />
                    </button>
                  </div>
                ) : (
                  cart.map((item, idx) => {
                    let weightMultiplier = 1;
                    if (item.weight === '500g') weightMultiplier = 1.9;
                    if (item.weight === '1kg') weightMultiplier = 3.5;
                    const computedPrice = Math.round(item.product.price * weightMultiplier);

                    return (
                      <div 
                        key={`${item.product.id}-${item.weight}-${idx}`} 
                        className={`flex gap-4 p-3 rounded-xl border ${
                          isDark ? 'bg-[#0f1d19]/40 border-luxuryGreen-900/60' : 'bg-gray-50 border-gray-200'
                        } transition-transform hover:-translate-y-0.5`}
                      >
                        <img 
                          src={item.product.image} 
                          alt={item.product.name} 
                          className="w-16 h-16 object-cover rounded-lg border border-luxuryGreen-900/40"
                        />
                        <div className="flex-1">
                          <h4 className={`text-xs font-bold leading-tight ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>{item.product.name}</h4>
                          <div className="flex justify-between items-center mt-2">
                            <span className={`text-[10px] px-2 py-0.5 rounded font-mono border ${
                              isDark ? 'bg-luxuryGreen-900 border-luxuryGreen-800 text-luxuryGold-500' : 'bg-luxuryGreen-50 border-luxuryGreen-200 text-luxuryGreen-900 font-bold'
                            }`}>
                              {item.weight}
                            </span>
                            <span className="text-xs font-mono font-bold text-luxuryGold-500">
                              ₹{computedPrice * item.quantity}
                            </span>
                          </div>
                          
                          <div className="flex justify-between items-center mt-3 pt-2 border-t border-luxuryGreen-950/20">
                            <div className="flex items-center gap-2">
                              <button 
                                onClick={() => handleUpdateCartQty(item.product.id, item.weight, item.quantity - 1)}
                                className={`w-5 h-5 rounded flex items-center justify-center font-bold text-xs ${
                                  isDark ? 'bg-luxuryGreen-900 hover:bg-luxuryGreen-800 text-white' : 'bg-gray-200 hover:bg-gray-300 text-gray-800'
                                }`}
                              >
                                -
                              </button>
                              <span className="text-xs font-mono font-semibold">{item.quantity}</span>
                              <button 
                                onClick={() => handleUpdateCartQty(item.product.id, item.weight, item.quantity + 1)}
                                className={`w-5 h-5 rounded flex items-center justify-center font-bold text-xs ${
                                  isDark ? 'bg-luxuryGreen-900 hover:bg-luxuryGreen-800 text-white' : 'bg-gray-200 hover:bg-gray-300 text-gray-800'
                                }`}
                              >
                                +
                              </button>
                            </div>
                            
                            <button 
                              onClick={() => handleUpdateCartQty(item.product.id, item.weight, 0)}
                              className="text-gray-400 hover:text-red-500 p-1 transition-colors"
                            >
                              <Trash2 size={14} />
                            </button>
                          </div>
                        </div>
                      </div>
                    );
                  })
                )}
              </div>

              {/* Subtotals & Checkout */}
              {cart.length > 0 && (
                <div className="border-t border-luxuryGreen-950/60 pt-4 mt-4 space-y-3">
                  {/* Coupon Promo Row */}
                  <div className="flex gap-2">
                    <input
                      type="text"
                      placeholder="Enter promo (WELCOME10)"
                      value={couponCode}
                      onChange={(e) => setCouponCode(e.target.value)}
                      className={`flex-1 text-xs border rounded-lg px-3 py-2 focus:outline-none focus:border-luxuryGold-500 font-mono ${
                        isDark ? 'bg-luxuryGreen-950/40 border-luxuryGreen-900 text-white' : 'bg-gray-50 border-gray-200 text-gray-800'
                      }`}
                    />
                    <button 
                      onClick={handleApplyCoupon}
                      className="bg-luxuryGold-600 hover:bg-luxuryGold-500 text-luxuryGreen-950 font-semibold px-4 py-2 rounded-lg text-xs transition-transform active:scale-95 animate-pulse"
                    >
                      Apply
                    </button>
                  </div>

                  {appliedCoupon && (
                    <div className="text-[10px] text-emerald-400 bg-emerald-950/60 border border-emerald-900 px-3 py-1.5 rounded-lg font-mono flex justify-between">
                      <span>Applied: {appliedCoupon.code}</span>
                      <span>-{appliedCoupon.discount}% Off</span>
                    </div>
                  )}

                  {/* Calculations */}
                  <div className="space-y-1.5 text-xs font-mono">
                    <div className="flex justify-between">
                      <span className="text-gray-500">Subtotal</span>
                      <span className={isDark ? 'text-white' : 'text-gray-800'}>₹{cartSubtotal}</span>
                    </div>
                    {discountAmount > 0 && (
                      <div className="flex justify-between text-emerald-500">
                        <span>Discount</span>
                        <span>-₹{discountAmount}</span>
                      </div>
                    )}
                    <div className="flex justify-between text-gray-500">
                      <span>GST (5%)</span>
                      <span className={isDark ? 'text-white' : 'text-gray-800'}>₹{gstAmount}</span>
                    </div>
                    <div className="flex justify-between text-gray-500">
                      <span>Delivery Charge</span>
                      <span className={isDark ? 'text-white' : 'text-gray-800'}>{deliveryCharge === 0 ? 'FREE' : `₹${deliveryCharge}`}</span>
                    </div>
                    <div className="flex justify-between border-t border-luxuryGreen-950/40 pt-2 text-sm font-bold">
                      <span className={isDark ? 'text-white' : 'text-luxuryGreen-950'}>Estimated Total</span>
                      <span className="text-luxuryGold-500 font-bold">₹{cartTotal}</span>
                    </div>
                  </div>

                  <button 
                    onClick={() => {
                      setIsCartOpen(false);
                      setCheckoutStep(1);
                      setActivePage('checkout');
                    }}
                    className="w-full bg-gradient-to-r from-luxuryGold-600 to-luxuryGold-700 hover:from-luxuryGold-500 hover:to-luxuryGold-600 text-luxuryGreen-950 font-bold py-3 rounded-xl text-xs transition-all duration-300 shadow-lg hover:shadow-luxuryGold-500/20 flex items-center justify-center gap-2"
                  >
                    Proceed to Gourmet Checkout <ArrowRight size={14} />
                  </button>
                </div>
              )}
            </motion.div>
          </>
        )}
      </AnimatePresence>

      {/* Luxury Navigation Header */}
      <header className={`sticky top-0 z-30 backdrop-blur-md border-b transition-colors duration-300 ${
        isDark ? 'bg-[#09100d]/80 border-luxuryGreen-950/60' : 'bg-white/90 border-gray-200'
      }`}>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-20 flex justify-between items-center">
          
          {/* Logo */}
          <div 
            onClick={() => setActivePage('home')}
            className="flex items-center gap-2.5 cursor-pointer group"
          >
            <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-luxuryGold-500 to-luxuryGold-600 flex items-center justify-center shadow-lg group-hover:scale-105 transition-transform duration-300">
              <ShoppingBag className="text-luxuryGreen-950" size={20} />
            </div>
            <div>
              <span className={`font-serif text-xl tracking-wider font-bold block transition-colors group-hover:text-luxuryGold-500 ${
                isDark ? 'text-white' : 'text-luxuryGreen-950'
              }`}>NUCIS & CO.</span>
              <span className="text-[9px] uppercase tracking-widest text-luxuryGold-500 font-mono font-semibold block leading-none">Luxury Wellness</span>
            </div>
          </div>

          {/* Desktop Navigation Links */}
          <nav className="hidden lg:flex items-center gap-8 text-xs font-mono tracking-wider uppercase font-semibold">
            <button 
              onClick={() => setActivePage('home')}
              className={`hover:text-luxuryGold-500 transition-colors ${
                activePage === 'home' ? 'text-luxuryGold-500 border-b border-luxuryGold-500 pb-1' : (isDark ? 'text-gray-300' : 'text-luxuryGreen-900')
              }`}
            >
              Home
            </button>
            <button 
              onClick={() => setActivePage('shop')}
              className={`hover:text-luxuryGold-500 transition-colors ${
                activePage === 'shop' ? 'text-luxuryGold-500 border-b border-luxuryGold-500 pb-1' : (isDark ? 'text-gray-300' : 'text-luxuryGreen-900')
              }`}
            >
              Gourmet Shop
            </button>
            <button 
              onClick={() => setActivePage('dashboard')}
              className={`hover:text-luxuryGold-500 transition-colors ${
                activePage === 'dashboard' ? 'text-luxuryGold-500 border-b border-luxuryGold-500 pb-1' : (isDark ? 'text-gray-300' : 'text-luxuryGreen-900')
              }`}
            >
              My Dashboard
            </button>
            <button 
              onClick={() => setActivePage('admin')}
              className={`hover:text-luxuryGold-500 transition-colors ${
                activePage === 'admin' ? 'text-luxuryGold-500 border-b border-luxuryGold-500 pb-1' : (isDark ? 'text-gray-300' : 'text-luxuryGreen-900')
              }`}
            >
              Executive Admin
            </button>
            <button 
              onClick={() => setActivePage('vendor')}
              className={`hover:text-luxuryGold-500 transition-colors ${
                activePage === 'vendor' ? 'text-luxuryGold-500 border-b border-luxuryGold-500 pb-1' : (isDark ? 'text-gray-300' : 'text-luxuryGreen-900')
              }`}
            >
              Vendor Portal
            </button>
            <button 
              onClick={() => setActivePage('aws')}
              className={`hover:text-luxuryGold-500 transition-colors ${
                activePage === 'aws' ? 'text-luxuryGold-500 border-b border-luxuryGold-500 pb-1' : (isDark ? 'text-gray-300' : 'text-luxuryGreen-900')
              }`}
            >
              AWS Topology
            </button>
          </nav>

          {/* Quick Actions (Theme, Wishlist, Cart) */}
          <div className="flex items-center gap-3">
            {/* Theme Toggle */}
            <button 
              onClick={() => setIsDark(!isDark)}
              className={`p-2 rounded-lg border transition-all ${
                isDark ? 'border-luxuryGreen-900 bg-luxuryGreen-950/40 text-yellow-400 hover:bg-luxuryGreen-900' : 'border-gray-200 bg-white text-gray-600 hover:bg-gray-100 shadow-sm'
              }`}
            >
              {isDark ? <Sun size={16} /> : <Moon size={16} />}
            </button>

            {/* Wishlist Icon */}
            <button 
              onClick={() => {
                setActivePage('dashboard');
              }}
              className={`p-2 rounded-lg border relative transition-colors ${
                isDark ? 'border-luxuryGreen-900 bg-luxuryGreen-950/40 text-gray-300 hover:text-red-400' : 'border-gray-200 bg-white text-gray-600 hover:text-red-500 shadow-sm'
              }`}
            >
              <Heart size={16} />
              {wishlist.length > 0 && (
                <span className="absolute -top-1.5 -right-1.5 w-4 h-4 bg-red-500 text-white rounded-full text-[9px] flex items-center justify-center font-bold animate-pulse">
                  {wishlist.length}
                </span>
              )}
            </button>

            {/* Shopping Cart Trigger */}
            <button 
              onClick={() => setIsCartOpen(true)}
              className="bg-gradient-to-r from-luxuryGold-600 to-luxuryGold-700 hover:from-luxuryGold-500 hover:to-luxuryGold-600 text-luxuryGreen-950 px-4 py-2.5 rounded-xl font-mono text-xs font-bold transition-all duration-300 shadow-md flex items-center gap-2"
            >
              <ShoppingBag size={15} />
              <span className="hidden sm:inline">Bag</span>
              <span className="bg-[#14221e] text-luxuryGold-500 px-1.5 py-0.5 rounded text-[10px]">
                {cart.reduce((sum, item) => sum + item.quantity, 0)}
              </span>
            </button>

            {/* Mobile Menu Icon */}
            <button 
              onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
              className={`lg:hidden p-2 rounded-lg border ${
                isDark ? 'border-luxuryGreen-900 text-gray-300' : 'border-gray-200 text-gray-700 bg-white shadow-sm'
              }`}
            >
              <Menu size={16} />
            </button>
          </div>
        </div>

        {/* Mobile Navigation Drawer */}
        <AnimatePresence>
          {isMobileMenuOpen && (
            <motion.div 
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              className={`lg:hidden border-b px-6 py-4 flex flex-col gap-3 font-mono text-xs tracking-wider uppercase font-semibold ${
                isDark ? 'bg-[#0c1310] border-luxuryGreen-900 text-gray-300' : 'bg-white border-gray-200 text-luxuryGreen-950 shadow-md'
              }`}
            >
              {['Home', 'Shop', 'Dashboard', 'Admin', 'Vendor', 'AWS'].map((tab) => (
                <button
                  key={tab}
                  onClick={() => {
                    const pagesMap = { Home: 'home', Shop: 'shop', Dashboard: 'dashboard', Admin: 'admin', Vendor: 'vendor', AWS: 'aws' };
                    setActivePage(pagesMap[tab]);
                    setIsMobileMenuOpen(false);
                  }}
                  className={`text-left py-2 border-b hover:text-luxuryGold-500 ${
                    isDark ? 'border-luxuryGreen-950/40 text-gray-300' : 'border-gray-100 text-gray-800'
                  }`}
                >
                  {tab}
                </button>
              ))}
            </motion.div>
          )}
        </AnimatePresence>
      </header>

      {/* Main Pages Container */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 relative z-10">
        <AnimatePresence mode="wait">
          <motion.div
            key={activePage}
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -15 }}
            transition={{ duration: 0.25 }}
          >
            
            {/* 1. CUSTOMER WEBSITE (HOME PAGE) */}
            {activePage === 'home' && (
              <div className="space-y-16">
                
                {/* Hero section */}
                <section 
                  className="relative rounded-3xl overflow-hidden bg-cover bg-center min-h-[500px] flex items-center p-8 md:p-16 border shadow-xl" 
                  style={{ 
                    border: isDark ? '1px solid rgba(255, 255, 255, 0.05)' : '1px solid rgba(0, 0, 0, 0.05)',
                    backgroundImage: isDark
                      ? 'linear-gradient(to right, rgba(9,16,13,0.95), rgba(9,16,13,0.35)), url("https://images.unsplash.com/photo-1595855759920-86582396756a?auto=format&fit=crop&q=80&w=1200")'
                      : 'linear-gradient(to right, rgba(244,247,246,0.98), rgba(244,247,246,0.45)), url("https://images.unsplash.com/photo-1595855759920-86582396756a?auto=format&fit=crop&q=80&w=1200")'
                  }}
                >
                  <div className="max-w-2xl space-y-6">
                    <span className={`text-xs uppercase font-mono tracking-widest font-bold px-3.5 py-1.5 rounded-full inline-block border ${
                      isDark 
                        ? 'bg-[#14221e] border-luxuryGreen-850 text-luxuryGold-500' 
                        : 'bg-luxuryGreen-100 border-luxuryGreen-200 text-luxuryGreen-900'
                    }`}>
                      🍂 100% Organic Sourcing & Handpicked Excellence
                    </span>
                    <h1 className={`font-serif text-4xl sm:text-6xl font-bold leading-tight ${
                      isDark ? 'text-white' : 'text-luxuryGreen-950'
                    }`}>
                      Elevate Your Wellness with <span className="text-luxuryGold-500 italic font-medium">Nucis & Co.</span>
                    </h1>
                    <p className={`text-sm sm:text-base leading-relaxed font-sans max-w-lg ${
                      isDark ? 'text-gray-300' : 'text-luxuryGreen-900/90 font-medium'
                    }`}>
                      Immerse your body in luxury wellness. Experience the rich crunchy textures of royal Mangalore cashews, saffron Iranian pistachios, and fresh walnut halves. 
                    </p>
                    <div className="flex flex-col sm:flex-row gap-4 pt-2">
                      <button 
                        onClick={() => setActivePage('shop')}
                        className="bg-gradient-to-r from-luxuryGold-600 to-luxuryGold-700 hover:from-luxuryGold-500 hover:to-luxuryGold-600 text-luxuryGreen-950 font-bold px-8 py-3.5 rounded-xl text-xs transition-all duration-300 shadow-lg hover:shadow-luxuryGold-500/25 flex items-center justify-center gap-2"
                      >
                        Explore Gourmet Catalog <ChevronRight size={15} />
                      </button>
                      <button 
                        onClick={() => {
                          setSelectedProductId('gift-festive-gold');
                          setActivePage('details');
                        }}
                        className={`font-mono font-bold px-6 py-3.5 rounded-xl text-xs transition-colors flex items-center justify-center gap-2 border ${
                          isDark 
                            ? 'bg-luxuryGreen-950/80 border-luxuryGreen-800 text-luxuryGold-500 hover:bg-luxuryGreen-900' 
                            : 'bg-white border-gray-300 text-luxuryGreen-950 hover:bg-gray-50 shadow-sm'
                        }`}
                      >
                        Wellness Gift Boxes
                      </button>
                    </div>
                  </div>
                  
                  {/* Floating nut animation representation */}
                  <motion.div 
                    animate={{ y: [0, -10, 0] }}
                    transition={{ repeat: Infinity, duration: 4, ease: "easeInOut" }}
                    className={`absolute right-20 bottom-12 hidden lg:block w-48 h-48 rounded-2xl border backdrop-blur-sm p-4 text-center flex flex-col items-center justify-center shadow-xl ${
                      isDark ? 'bg-luxuryGreen-950/60 border-luxuryGreen-850' : 'bg-white/80 border-gray-250'
                    }`}
                  >
                    <img 
                      src="https://images.unsplash.com/photo-1508061253366-f7da188bdf94?auto=format&fit=crop&q=80&w=150" 
                      alt="nut animation" 
                      className="w-24 h-24 object-cover rounded-full border border-luxuryGold-600/30 mb-2 shadow-sm"
                    />
                    <span className={`text-[10px] uppercase font-mono tracking-widest font-bold block ${
                      isDark ? 'text-luxuryGold-500' : 'text-luxuryGreen-950'
                    }`}>100% Bold Badam</span>
                  </motion.div>
                </section>

                {/* Category Slider */}
                <section className="space-y-6">
                  <div className="flex justify-between items-end border-b border-luxuryGreen-950 pb-4">
                    <div>
                      <span className="text-xs uppercase tracking-widest text-luxuryGold-500 font-mono font-bold">Nature's Tiers</span>
                      <h2 className={`text-3xl font-bold font-serif mt-1 ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>Shop by Wellness Category</h2>
                    </div>
                    <button 
                      onClick={() => setActivePage('shop')}
                      className="text-xs font-mono text-luxuryGold-600 hover:text-luxuryGold-500 flex items-center gap-1"
                    >
                      View All Shop Catalog <ChevronRight size={14} />
                    </button>
                  </div>
                  
                  <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
                    {['Badam', 'Cashew', 'Dates', 'Seeds', 'Gift Packs'].map((cat) => {
                      const iconsMap = { Badam: '🌰', Cashew: '🥐', Dates: '🌴', Seeds: '🌾', 'Gift Packs': '🎁' };
                      const descMap = { Badam: 'Raw & bold almonds', Cashew: 'Milky W180 selection', Dates: 'Sweet Medjool treasures', Seeds: 'Omega superfood mix', 'Gift Packs': 'Velvet-mahogany chests' };
                      return (
                        <div 
                          key={cat}
                          onClick={() => {
                            setSelectedCategory(cat);
                            setActivePage('shop');
                          }}
                          className={`cursor-pointer p-5 rounded-2xl border text-center transition-all duration-300 hover:-translate-y-1 hover:shadow-xl ${
                            isDark 
                              ? 'bg-luxuryGreen-950/40 border-luxuryGreen-900/60 hover:bg-luxuryGreen-900 hover:border-luxuryGold-600/30' 
                              : 'bg-white border-gray-200 hover:border-luxuryGold-500/30 hover:bg-luxuryGreen-50 shadow-sm'
                          }`}
                        >
                          <span className="text-3xl block mb-2">{iconsMap[cat]}</span>
                          <h3 className={`text-sm font-bold mb-1 ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>{cat}</h3>
                          <p className="text-[10px] text-gray-500 font-mono">{descMap[cat]}</p>
                        </div>
                      );
                    })}
                  </div>
                </section>

                {/* Best Sellers */}
                <section className="space-y-6">
                  <div className="border-b border-luxuryGreen-950 pb-4">
                    <span className="text-xs uppercase tracking-widest text-luxuryGold-500 font-mono font-bold">Acclaimed Organics</span>
                    <h2 className={`text-3xl font-bold font-serif mt-1 ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>Our Elite Best Sellers</h2>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
                    {productsList.slice(0, 4).map((prod) => (
                      <div 
                        key={prod.id} 
                        className={`group relative rounded-2xl border overflow-hidden transition-all duration-300 hover:-translate-y-1 hover:shadow-2xl flex flex-col justify-between ${
                          isDark 
                            ? 'bg-luxuryGreen-950/20 border-luxuryGreen-900/60 hover:border-luxuryGold-500/30' 
                            : 'bg-white border-gray-200 hover:border-luxuryGold-500/30 shadow-md'
                        }`}
                      >
                        {/* Image & tag */}
                        <div className="relative overflow-hidden cursor-pointer" onClick={() => { setSelectedProductId(prod.id); setActivePage('details'); }}>
                          <img 
                            src={prod.image} 
                            alt={prod.name} 
                            className="w-full h-48 object-cover group-hover:scale-105 transition-transform duration-550"
                          />
                          <span className="absolute top-3 left-3 bg-[#0c1310] border border-luxuryGold-500/40 text-luxuryGold-500 text-[9px] uppercase font-mono font-semibold px-2 py-0.5 rounded">
                            {prod.tag}
                          </span>
                          <button 
                            onClick={(e) => { e.stopPropagation(); handleToggleWishlist(prod.id); }}
                            className={`absolute top-3 right-3 p-1.5 rounded-full backdrop-blur-md border ${
                              wishlist.includes(prod.id) ? 'bg-red-500/20 border-red-500 text-red-500' : 'bg-black/30 border-white/20 text-white hover:text-red-400'
                            }`}
                          >
                            <Heart size={14} fill={wishlist.includes(prod.id) ? 'currentColor' : 'none'} />
                          </button>
                        </div>

                        {/* Title, rating, price */}
                        <div className="p-4 flex-1 flex flex-col justify-between">
                          <div>
                            <div className="flex justify-between items-center text-xs text-gray-500 font-mono mb-1">
                              <span className={isDark ? 'text-gray-400' : 'text-luxuryGreen-700/80 font-bold'}>{prod.category}</span>
                              <span className="flex items-center gap-0.5 text-luxuryGold-500">
                                <Star size={12} fill="currentColor" /> {prod.rating}
                              </span>
                            </div>
                            <h3 
                              onClick={() => { setSelectedProductId(prod.id); setActivePage('details'); }}
                              className={`text-xs font-bold leading-snug cursor-pointer hover:text-luxuryGold-500 transition-colors ${
                                isDark ? 'text-white' : 'text-luxuryGreen-950'
                              }`}
                            >
                              {prod.name}
                            </h3>
                          </div>

                          <div className="flex justify-between items-center mt-4">
                            <span className="text-sm font-mono font-bold text-luxuryGold-500">₹{prod.price} <span className="text-[10px] text-gray-500 font-normal">/ 250g</span></span>
                            <button 
                              onClick={() => handleAddToCart(prod.id, '250g', 1)}
                              className={`font-mono text-[10px] font-bold px-3 py-1.5 rounded-lg transition-all flex items-center gap-1 active:scale-95 border ${
                                isDark 
                                  ? 'bg-[#14221e] border-luxuryGreen-800 text-luxuryGold-500 hover:bg-luxuryGold-600 hover:text-luxuryGreen-950' 
                                  : 'bg-luxuryGreen-50 border-luxuryGreen-200 text-luxuryGreen-900 hover:bg-luxuryGold-600 hover:text-luxuryGreen-950'
                              }`}
                            >
                              <Plus size={12} /> Add
                            </button>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </section>

                {/* Trending section with Promo banners */}
                <section className={`rounded-3xl border p-8 md:p-12 grid grid-cols-1 md:grid-cols-2 gap-8 items-center shadow-lg ${
                  isDark ? 'bg-gradient-to-r from-luxuryGreen-950 to-[#060b09] border-luxuryGreen-900' : 'bg-gradient-to-r from-luxuryGreen-100 to-luxuryGreen-50 border-luxuryGreen-200'
                }`}>
                  <div className="space-y-6">
                    <span className="text-xs font-mono uppercase text-luxuryGold-500 tracking-widest font-bold">Limited Wellness Offer</span>
                    <h2 className={`text-3xl font-serif font-bold leading-tight ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>Celebrate Lifestyle Health with 15% Savings</h2>
                    <p className={`text-sm leading-relaxed font-sans max-w-md ${isDark ? 'text-gray-300' : 'text-luxuryGreen-900/80 font-medium'}`}>
                      Get premium organic almonds, hand-split saffron pistachios, and executive mahogany gift box selections at premium discounts. Take active control of your vitality.
                    </p>
                    <div className={`border px-4 py-3 rounded-xl max-w-sm flex justify-between items-center font-mono ${
                      isDark ? 'bg-[#0b1310] border-luxuryGreen-950' : 'bg-white border-luxuryGreen-200 shadow-inner'
                    }`}>
                      <div>
                        <span className="text-[10px] text-gray-500 block uppercase">USE CODE AT CHECKOUT</span>
                        <span className="text-base text-luxuryGold-500 font-bold">LUXURYHEALTH</span>
                      </div>
                      <button 
                        onClick={() => {
                          setCouponCode('LUXURYHEALTH');
                          alert('Discount code LUXURYHEALTH copied to cart drawer. Apply it during checkout!');
                        }}
                        className="text-[10px] bg-luxuryGreen-900 border border-luxuryGreen-850 text-luxuryGold-500 px-3 py-1.5 rounded hover:bg-luxuryGold-600 hover:text-luxuryGreen-950 transition-colors font-bold"
                      >
                        COPY CODE
                      </button>
                    </div>
                  </div>
                  <div className="relative">
                    <img 
                      src="https://images.unsplash.com/photo-1549465220-1a8b9238cd48?auto=format&fit=crop&q=80&w=600" 
                      alt="gift promo" 
                      className="rounded-2xl border border-luxuryGreen-900/60 shadow-2xl object-cover h-64 w-full"
                    />
                    <div className="absolute -bottom-4 -left-4 bg-[#0c1310] border border-luxuryGold-500/20 p-3 rounded-xl text-center hidden md:block shadow-lg">
                      <span className="text-xs font-mono text-luxuryGold-500 font-bold block">Festive Hamper Gold</span>
                      <span className="text-[9px] text-gray-400 block font-mono">Starts at ₹1899</span>
                    </div>
                  </div>
                </section>

                {/* Health Benefits Section */}
                <section className="space-y-6">
                  <div className="border-b border-luxuryGreen-950 pb-4 text-center md:text-left">
                    <span className="text-xs uppercase tracking-widest text-luxuryGold-500 font-mono font-bold">Botanical Value</span>
                    <h2 className={`text-3xl font-bold font-serif mt-1 ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>Structured Nutritive Benefits</h2>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <div className={`p-6 rounded-2xl border text-center md:text-left shadow-sm ${
                      isDark ? 'bg-luxuryGreen-950/20 border-luxuryGreen-900/60' : 'bg-white border-gray-200'
                    }`}>
                      <span className="text-3xl block mb-3">🧠</span>
                      <h3 className={`text-base font-bold mb-2 ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>Alpha-Linolenic Acid (Brain)</h3>
                      <p className="text-xs text-gray-500 leading-relaxed font-sans">
                        Our Kashmiri walnuts contain dense ratios of plant-based Omega-3 fatty acids which protect cognitive functions, memory recall, and focus.
                      </p>
                    </div>
                    <div className={`p-6 rounded-2xl border text-center md:text-left shadow-sm ${
                      isDark ? 'bg-luxuryGreen-950/20 border-luxuryGreen-900/60' : 'bg-white border-gray-200'
                    }`}>
                      <span className="text-3xl block mb-3">❤️</span>
                      <h3 className={`text-base font-bold mb-2 ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>Monounsaturated Fats (Heart)</h3>
                      <p className="text-xs text-gray-500 leading-relaxed font-sans">
                        Mangalore W180 Cashews are slow-roasted and packed with monounsaturated fats (oleic acid) which reduce LDL bad cholesterol and guard artery elasticity.
                      </p>
                    </div>
                    <div className={`p-6 rounded-2xl border text-center md:text-left shadow-sm ${
                      isDark ? 'bg-luxuryGreen-950/20 border-luxuryGreen-900/60' : 'bg-white border-gray-200'
                    }`}>
                      <span className="text-3xl block mb-3">⚡</span>
                      <h3 className={`text-base font-bold mb-2 ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>Caramel Potassium (Energy)</h3>
                      <p className="text-xs text-gray-500 leading-relaxed font-sans">
                        Crown jewel Medjool Dates provide instant, slow-burning glycogen energy and mineral potassium, ideal for fitness routines and muscular hydration.
                      </p>
                    </div>
                  </div>
                </section>

                {/* Subscriptions plans */}
                <section className="space-y-6">
                  <div className="border-b border-luxuryGreen-950 pb-4 text-center">
                    <span className="text-xs uppercase tracking-widest text-luxuryGold-500 font-mono font-bold">Continuous Wellness</span>
                    <h2 className={`text-3xl font-bold font-serif mt-1 ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>Gourmet Nutrition Subscriptions</h2>
                    <p className="text-xs text-gray-500 mt-1 font-mono">15% Discount on recurring shipments. Zero obligations. Cancel anytime.</p>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-3 gap-6 max-w-4xl mx-auto">
                    <div className={`p-6 rounded-2xl border flex flex-col justify-between shadow-md ${
                      isDark ? 'bg-luxuryGreen-950/30 border-luxuryGreen-900' : 'bg-white border-gray-200'
                    }`}>
                      <div>
                        <span className="text-[10px] uppercase font-mono tracking-widest text-luxuryGold-500 font-semibold mb-1 block">Fitness Tier</span>
                        <h3 className={`text-lg font-serif font-bold mb-3 ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>Weekly Seed Supply</h3>
                        <p className="text-[10px] text-gray-500 mb-4 leading-relaxed">
                          A 500g recurring shipment of our premium 7-in-1 Seed Mix, containing chia, flax, and cranberries. Delivered fresh every Monday morning.
                        </p>
                        <div className="text-2xl font-mono font-bold text-luxuryGold-500 mb-4">₹466 <span className="text-xs text-gray-500 font-normal">/ week</span></div>
                      </div>
                      <button 
                        onClick={() => {
                          setUserSubscriptions(prev => [
                            { id: `SUB-${Math.floor(100+Math.random()*900)}`, name: 'Weekly Seed Supply', frequency: 'Weekly', weight: '500g', price: 466, nextDate: 'June 02, 2026', status: 'Active' },
                            ...prev
                          ]);
                          alert('Weekly Seed subscription successfully started! Manage it in your user dashboard.');
                          setActivePage('dashboard');
                        }}
                        className="w-full bg-luxuryGreen-900 border border-luxuryGreen-850 hover:bg-luxuryGold-600 hover:text-luxuryGreen-950 text-luxuryGold-500 font-mono font-bold py-2 rounded-xl text-xs transition-colors"
                      >
                        Subscribe Weekly
                      </button>
                    </div>

                    <div className={`p-6 rounded-2xl border relative flex flex-col justify-between shadow-xl ${
                      isDark ? 'bg-[#0f1d19] border-luxuryGold-500/40 shadow-2xl' : 'bg-white border-luxuryGold-500 shadow-xl'
                    }`}>
                      <span className="absolute -top-3 left-1/2 -translate-x-1/2 bg-luxuryGold-600 text-luxuryGreen-950 font-bold px-3 py-0.5 rounded-full text-[9px] uppercase tracking-widest font-mono shadow-md">
                        LUXURY RECOMENDED
                      </span>
                      <div>
                        <span className="text-[10px] uppercase font-mono tracking-widest text-luxuryGold-500 font-semibold mb-1 block">Royal Tier</span>
                        <h3 className={`text-lg font-serif font-bold mb-3 ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>Monthly Brain & Heart Combo</h3>
                        <p className="text-[10px] text-gray-500 mb-4 leading-relaxed">
                          The absolute wellness essential. Contains California Almonds (500g), Royal Cashews (500g), and Walnut halves (500g) shipped securely every month.
                        </p>
                        <div className="text-2xl font-mono font-bold text-luxuryGold-500 mb-4">₹2299 <span className="text-xs text-gray-500 font-normal">/ month</span></div>
                      </div>
                      <button 
                        onClick={() => {
                          setUserSubscriptions(prev => [
                            { id: `SUB-${Math.floor(100+Math.random()*900)}`, name: 'Monthly Brain & Heart Combo', frequency: 'Monthly', weight: '1.5kg', price: 2299, nextDate: 'June 25, 2026', status: 'Active' },
                            ...prev
                          ]);
                          alert('Monthly Brain & Heart Combo subscription successfully started! View active subscription in your user dashboard.');
                          setActivePage('dashboard');
                        }}
                        className="w-full bg-gradient-to-r from-luxuryGold-600 to-luxuryGold-700 hover:from-luxuryGold-500 hover:to-luxuryGold-600 text-luxuryGreen-950 font-bold py-2.5 rounded-xl text-xs transition-colors shadow-lg"
                      >
                        Subscribe Monthly
                      </button>
                    </div>

                    <div className={`p-6 rounded-2xl border flex flex-col justify-between shadow-md ${
                      isDark ? 'bg-luxuryGreen-950/30 border-luxuryGreen-900' : 'bg-white border-gray-200'
                    }`}>
                      <div>
                        <span className="text-[10px] uppercase font-mono tracking-widest text-luxuryGold-500 font-semibold mb-1 block">Corporate Premium</span>
                        <h3 className={`text-lg font-serif font-bold mb-3 ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>Quarterly Gift & Wellness Tray</h3>
                        <p className="text-[10px] text-gray-500 mb-4 leading-relaxed">
                          Keep your boardrooms, offices, or loved ones stocked with healthy wellness gift trays, sent every quarter in velvet Mahogany chests.
                        </p>
                        <div className="text-2xl font-mono font-bold text-luxuryGold-500 mb-4">₹4999 <span className="text-xs text-gray-500 font-normal">/ quarter</span></div>
                      </div>
                      <button 
                        onClick={() => {
                          setUserSubscriptions(prev => [
                            { id: `SUB-${Math.floor(100+Math.random()*900)}`, name: 'Quarterly Gift & Wellness Tray', frequency: 'Quarterly', weight: '3kg', price: 4999, nextDate: 'August 15, 2026', status: 'Active' },
                            ...prev
                          ]);
                          alert('Quarterly Gift & Wellness Tray subscription successfully started! Review status on your user dashboard.');
                          setActivePage('dashboard');
                        }}
                        className="w-full bg-luxuryGreen-900 border border-luxuryGreen-850 hover:bg-luxuryGold-600 hover:text-luxuryGreen-950 text-luxuryGold-500 font-mono font-bold py-2 rounded-xl text-xs transition-colors"
                      >
                        Subscribe Quarterly
                      </button>
                    </div>
                  </div>
                </section>

                {/* Editorial Blogs */}
                <section className="space-y-6">
                  <div className="border-b border-luxuryGreen-950 pb-4 text-center md:text-left">
                    <span className="text-xs uppercase tracking-widest text-luxuryGold-500 font-mono font-bold">Wellness Editorial</span>
                    <h2 className={`text-3xl font-bold font-serif mt-1 ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>Our Wellness Blog & Research</h2>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    {blogs.map((blog) => (
                      <div 
                        key={blog.id} 
                        className={`p-4 rounded-2xl border flex flex-col md:flex-row gap-4 items-center shadow-sm ${
                          isDark ? 'bg-luxuryGreen-950/20 border-luxuryGreen-900/60' : 'bg-white border-gray-200'
                        } transition-transform hover:-translate-y-0.5`}
                      >
                        <img 
                          src={blog.image} 
                          alt={blog.title} 
                          className="w-full md:w-32 h-32 object-cover rounded-xl border border-luxuryGreen-900/30 shadow-sm"
                        />
                        <div className="flex-1 space-y-2">
                          <div className="flex justify-between items-center text-[10px] text-gray-500 font-mono">
                            <span>{blog.date}</span>
                            <span>{blog.readTime}</span>
                          </div>
                          <h3 className={`text-xs font-bold leading-snug hover:text-luxuryGold-500 cursor-pointer ${
                            isDark ? 'text-white' : 'text-luxuryGreen-950'
                          }`}>{blog.title}</h3>
                          <p className="text-[10px] text-gray-500 leading-relaxed font-sans">{blog.excerpt}</p>
                        </div>
                      </div>
                    ))}
                  </div>
                </section>

                {/* Review section */}
                <section className="space-y-6">
                  <div className="border-b border-luxuryGreen-950 pb-4 text-center">
                    <span className="text-xs uppercase tracking-widest text-luxuryGold-500 font-mono font-bold">Customer Loyalty</span>
                    <h2 className={`text-3xl font-serif font-bold mt-1 ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>Gourmet Wellness Testimonials</h2>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                    {reviews.map((rev, idx) => (
                      <div 
                        key={idx} 
                        className={`p-5 rounded-2xl border shadow-sm ${
                          isDark ? 'bg-luxuryGreen-950/20 border-luxuryGreen-900/40' : 'bg-white border-gray-200'
                        } flex flex-col justify-between`}
                      >
                        <div className="space-y-3">
                          <div className="flex gap-0.5 text-luxuryGold-500">
                            {[...Array(rev.rating)].map((_, i) => (
                              <Star key={i} size={12} fill="currentColor" />
                            ))}
                          </div>
                          <p className={`text-[10px] italic font-sans ${isDark ? 'text-gray-300' : 'text-gray-600'}`}>"{rev.comment}"</p>
                        </div>
                        <div className="flex justify-between items-center mt-4 pt-2 border-t border-luxuryGreen-950/20 text-[10px] font-mono">
                          <span className={`font-bold ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>{rev.name}</span>
                          <span className="text-gray-500">{rev.date}</span>
                        </div>
                      </div>
                    ))}
                  </div>
                </section>

                {/* FAQ section */}
                <section className="space-y-6 max-w-4xl mx-auto">
                  <div className="border-b border-luxuryGreen-950 pb-4 text-center">
                    <span className="text-xs uppercase tracking-widest text-luxuryGold-500 font-mono font-bold">Information Panel</span>
                    <h2 className={`text-3xl font-serif font-bold mt-1 ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>FAQ & Organic Auditing Inquiries</h2>
                  </div>

                  <div className="space-y-4">
                    {faqs.map((faq, idx) => (
                      <details 
                        key={idx} 
                        className={`p-4 rounded-xl border group cursor-pointer shadow-sm ${
                          isDark ? 'bg-luxuryGreen-950/20 border-luxuryGreen-900/60' : 'bg-white border-gray-200'
                        }`}
                      >
                        <summary className={`text-xs font-bold font-sans hover:text-luxuryGold-500 flex justify-between items-center outline-none list-none ${
                          isDark ? 'text-white' : 'text-luxuryGreen-950'
                        }`}>
                          <span>{faq.q}</span>
                          <ChevronDown size={14} className="text-luxuryGold-500 group-open:rotate-180 transition-transform" />
                        </summary>
                        <p className="text-[11px] text-gray-500 mt-2 leading-relaxed font-sans border-t border-luxuryGreen-950/20 pt-2">
                          {faq.a}
                        </p>
                      </details>
                    ))}
                  </div>
                </section>
                
                {/* Premium Editorial Footer */}
                <footer className="border-t border-luxuryGreen-950 pt-12 pb-6 text-xs text-gray-500 font-mono text-center md:text-left">
                  <div className="grid grid-cols-1 md:grid-cols-4 gap-8 mb-8">
                    <div className="space-y-4 text-center md:text-left">
                      <div className="flex items-center justify-center md:justify-start gap-2">
                        <div className="w-8 h-8 rounded bg-luxuryGold-600 flex items-center justify-center shadow-md">
                          <ShoppingBag size={16} className="text-luxuryGreen-950" />
                        </div>
                        <span className="text-sm font-serif font-bold text-white tracking-wider">NUCIS & CO.</span>
                      </div>
                      <p className="text-[10px] text-gray-500 leading-relaxed font-sans">
                        Pioneers in high-altitude organic dry fruit sorting, slowly roasted under pink Saffron infusions to lock in natural nutritive compounds.
                      </p>
                    </div>
                    <div>
                      <h4 className={`font-bold uppercase mb-3 ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>Product Catalog</h4>
                      <ul className="space-y-1.5 text-[11px]">
                        <li><button onClick={() => { setSelectedCategory('Badam'); setActivePage('shop'); }} className="hover:text-luxuryGold-500 text-gray-500">Premium California Badam</button></li>
                        <li><button onClick={() => { setSelectedCategory('Cashew'); setActivePage('shop'); }} className="hover:text-luxuryGold-500 text-gray-500">Jumbo Royal Cashews</button></li>
                        <li><button onClick={() => { setSelectedCategory('Dates'); setActivePage('shop'); }} className="hover:text-luxuryGold-500 text-gray-500">Imperial Jordanian Medjools</button></li>
                        <li><button onClick={() => { setSelectedCategory('Seeds'); setActivePage('shop'); }} className="hover:text-luxuryGold-500 text-gray-500">Superfood 7-in-1 Omega Mix</button></li>
                      </ul>
                    </div>
                    <div>
                      <h4 className={`font-bold uppercase mb-3 ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>Wellness Hub</h4>
                      <ul className="space-y-1.5 text-[11px]">
                        <li><button onClick={() => setActivePage('home')} className="hover:text-luxuryGold-500 text-gray-500">Editorial Research Articles</button></li>
                        <li><button onClick={() => setActivePage('home')} className="hover:text-luxuryGold-500 text-gray-500">Organic Sourcing Audit logs</button></li>
                        <li><button onClick={() => setActivePage('dashboard')} className="hover:text-luxuryGold-500 text-gray-500">Loyalty Rewards Program</button></li>
                      </ul>
                    </div>
                    <div>
                      <h4 className={`font-bold uppercase mb-3 ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>Corporate Details</h4>
                      <p className="text-[10px] leading-relaxed text-gray-500 font-sans">
                        Nucis & Co. India Private Ltd.<br />
                        GSTIN: 29AABCN8831A1ZC<br />
                        Customer Care: 1800-NUCIS-GOLD<br />
                        Email: wellness@nucis.co
                      </p>
                    </div>
                  </div>
                  <div className="border-t border-luxuryGreen-950/60 pt-4 flex flex-col md:flex-row justify-between items-center gap-2 text-[10px] text-gray-600">
                    <span>© 2026 Nucis & Co. dry fruits & organic health. All Rights Reserved.</span>
                    <span className="flex items-center gap-1"><Lock size={12} className="text-luxuryGold-500" /> SSL SECURE 256-bit encrypted transactions</span>
                  </div>
                </footer>
              </div>
            )}

            {/* 2. PRODUCT LISTING PAGE */}
            {activePage === 'shop' && (
              <div className="space-y-6">
                
                {/* Banner */}
                <div className={`border rounded-3xl p-8 flex flex-col md:flex-row justify-between items-center gap-6 shadow-md ${
                  isDark ? 'bg-gradient-to-r from-luxuryGreen-950 to-[#0c1310] border-luxuryGreen-900' : 'bg-gradient-to-r from-luxuryGreen-100 to-luxuryGreen-50 border-luxuryGreen-200'
                }`}>
                  <div>
                    <span className="text-xs uppercase font-mono tracking-widest text-luxuryGold-500 font-semibold mb-1 block">Elite Storefront</span>
                    <h1 className={`font-serif text-3xl md:text-4xl font-bold leading-tight ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>Nucis Gourmet Dry Fruits</h1>
                    <p className="text-xs text-gray-500 mt-1 max-w-md font-sans font-medium">Handpicked and triple-hand-sorted bold nuts, slow-roasted under low temperatures to preserve organic fibers, vitamins, and buttery taste profiles.</p>
                  </div>
                  {/* Category Pill select */}
                  <div className="flex gap-2 flex-wrap scrollbar-none font-mono text-[10px] uppercase font-bold">
                    {['All', 'Badam', 'Cashew', 'Dates', 'Seeds', 'Gift Packs'].map((cat) => (
                      <button 
                        key={cat} 
                        onClick={() => setSelectedCategory(cat)}
                        className={`px-4 py-2 rounded-full border transition-all ${
                          selectedCategory === cat 
                            ? 'bg-luxuryGold-600 border-luxuryGold-500 text-luxuryGreen-950 font-bold' 
                            : (isDark ? 'bg-luxuryGreen-950/40 border-luxuryGreen-900 text-gray-300 hover:bg-luxuryGreen-900' : 'bg-white border-gray-200 text-gray-650 hover:bg-gray-100')
                        }`}
                      >
                        {cat}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Filters Sidebar + Grid layout */}
                <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
                  
                  {/* Filters Side Column */}
                  <div className={`p-5 rounded-2xl border h-fit space-y-6 shadow-sm ${
                    isDark ? 'bg-luxuryGreen-950/20 border-luxuryGreen-900/60' : 'bg-white border-gray-250'
                  }`}>
                    <div className="flex justify-between items-center border-b border-luxuryGreen-950 pb-3">
                      <span className={`text-xs font-mono font-bold flex items-center gap-1.5 ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>
                        <SlidersHorizontal size={14} className="text-luxuryGold-500" /> Advanced Filters
                      </span>
                      <button 
                        onClick={() => {
                          setSearchTerm('');
                          setSelectedCategory('All');
                          setPriceRange(3000);
                          setStockOnly(false);
                        }}
                        className="text-[9px] font-mono text-gray-500 hover:text-luxuryGold-500"
                      >
                        Reset All
                      </button>
                    </div>

                    {/* Search Field */}
                    <div className="space-y-2">
                      <label className="text-[10px] uppercase font-mono tracking-wider font-bold text-luxuryGold-500 block">Search Product</label>
                      <div className="relative">
                        <input
                          type="text"
                          placeholder="e.g. Badam, Cashew..."
                          value={searchTerm}
                          onChange={(e) => setSearchTerm(e.target.value)}
                          className={`w-full text-xs rounded-xl px-3.5 py-2.5 pl-9 focus:outline-none focus:border-luxuryGold-500 ${
                            isDark ? 'bg-luxuryGreen-950/60 border-luxuryGreen-900 text-white' : 'bg-gray-50 border-gray-200 text-gray-800'
                          }`}
                        />
                        <Search size={14} className="absolute left-3 top-3.5 text-gray-400" />
                      </div>
                    </div>

                    {/* Price Slider */}
                    <div className="space-y-2">
                      <div className="flex justify-between items-center text-[10px] uppercase font-mono tracking-wider font-bold">
                        <label className="text-luxuryGold-500">Max Budget</label>
                        <span className={isDark ? 'text-white' : 'text-luxuryGreen-950 font-bold'}>₹{priceRange}</span>
                      </div>
                      <input
                        type="range"
                        min="250"
                        max="3000"
                        step="50"
                        value={priceRange}
                        onChange={(e) => setPriceRange(Number(e.target.value))}
                        className="w-full accent-luxuryGold-600 bg-luxuryGreen-950 h-1.5 rounded-lg"
                      />
                      <div className="flex justify-between text-[9px] font-mono text-gray-500">
                        <span>₹250</span>
                        <span>₹3000</span>
                      </div>
                    </div>

                    {/* Stock only toggle */}
                    <div className="flex items-center justify-between border-t border-luxuryGreen-950/40 pt-4 text-xs font-mono">
                      <label className="text-gray-500 cursor-pointer" htmlFor="stockToggle">In Stock Only</label>
                      <input 
                        id="stockToggle"
                        type="checkbox" 
                        checked={stockOnly}
                        onChange={(e) => setStockOnly(e.target.checked)}
                        className="accent-luxuryGold-600 w-4 h-4"
                      />
                    </div>
                  </div>

                  {/* Main Grid View */}
                  <div className="lg:col-span-3 space-y-4">
                    {/* Header: Sort / View mode */}
                    <div className="flex justify-between items-center text-xs font-mono text-gray-500">
                      <span>Found <span className={`font-bold font-mono ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>{filteredProducts.length}</span> luxury dry fruits</span>
                      <div className="flex items-center gap-3">
                        <select 
                          value={sortBy}
                          onChange={(e) => setSortBy(e.target.value)}
                          className={`text-[10px] px-2.5 py-1.5 rounded-lg border focus:outline-none focus:border-luxuryGold-500 uppercase font-bold tracking-wider ${
                            isDark ? 'bg-[#0f1d19]/40 border-luxuryGreen-900 text-white' : 'bg-white border-gray-250 text-gray-800 shadow-sm'
                          }`}
                        >
                          <option value="popular">Popularity</option>
                          <option value="price-low">Price: Low to High</option>
                          <option value="price-high">Price: High to Low</option>
                          <option value="rating">Top Rated</option>
                        </select>
                        <div className="hidden sm:flex border border-luxuryGreen-900 rounded-lg overflow-hidden text-[10px] uppercase font-bold shadow-sm">
                          <button 
                            onClick={() => setViewMode('grid')}
                            className={`px-3 py-1.5 ${viewMode === 'grid' ? 'bg-luxuryGold-600 text-luxuryGreen-950 font-bold' : (isDark ? 'bg-luxuryGreen-950/40 text-gray-400' : 'bg-white text-gray-500')}`}
                          >
                            Grid
                          </button>
                          <button 
                            onClick={() => setViewMode('list')}
                            className={`px-3 py-1.5 ${viewMode === 'list' ? 'bg-luxuryGold-600 text-luxuryGreen-950 font-bold' : (isDark ? 'bg-luxuryGreen-950/40 text-gray-400' : 'bg-white text-gray-500')}`}
                          >
                            List
                          </button>
                        </div>
                      </div>
                    </div>

                    {/* Products display */}
                    {filteredProducts.length === 0 ? (
                      <div className="text-center py-16 bg-[#0c1310]/60 border border-luxuryGreen-950 rounded-2xl shadow-sm">
                        <SlidersHorizontal size={40} className="mx-auto text-luxuryGreen-850 animate-pulse mb-3" />
                        <h3 className="text-sm font-bold text-white">No organic matches found</h3>
                        <p className="text-xs text-gray-400 mt-1 max-w-[280px] mx-auto font-sans">Try expanding your budget slider or clearing the active search filter term.</p>
                      </div>
                    ) : (
                      <div className={viewMode === 'grid' ? 'grid grid-cols-1 sm:grid-cols-3 gap-6' : 'space-y-4'}>
                        {filteredProducts.map((prod) => (
                          <div 
                            key={prod.id} 
                            className={`group relative rounded-2xl border overflow-hidden transition-all duration-300 hover:-translate-y-1 hover:shadow-2xl flex ${
                              viewMode === 'grid' ? 'flex-col justify-between' : 'flex-col sm:flex-row gap-4 items-center p-3'
                            } ${
                              isDark 
                                ? 'bg-[#0f1d19]/20 border-luxuryGreen-900/60 hover:border-luxuryGold-500/30' 
                                : 'bg-white border-gray-200 hover:border-luxuryGold-500/30 shadow-md'
                            }`}
                          >
                            {/* Image Container */}
                            <div 
                              className={`relative overflow-hidden cursor-pointer ${viewMode === 'grid' ? 'w-full h-48' : 'w-full sm:w-32 h-32'}`}
                              onClick={() => { setSelectedProductId(prod.id); setActivePage('details'); }}
                            >
                              <img 
                                src={prod.image} 
                                alt={prod.name} 
                                className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-550"
                              />
                              <span className="absolute top-3 left-3 bg-[#0c1310] border border-luxuryGold-500/40 text-luxuryGold-500 text-[9px] uppercase font-mono font-semibold px-2 py-0.5 rounded">
                                {prod.tag}
                              </span>
                              <button 
                                onClick={(e) => { e.stopPropagation(); handleToggleWishlist(prod.id); }}
                                className={`absolute top-3 right-3 p-1.5 rounded-full backdrop-blur-md border ${
                                  wishlist.includes(prod.id) ? 'bg-red-500/20 border-red-500 text-red-500' : 'bg-black/30 border-white/20 text-white hover:text-red-400'
                                }`}
                              >
                                <Heart size={14} fill={wishlist.includes(prod.id) ? 'currentColor' : 'none'} />
                              </button>
                            </div>

                            {/* Details Container */}
                            <div className="p-4 flex-1 flex flex-col justify-between w-full">
                              <div>
                                <div className="flex justify-between items-center text-xs font-mono mb-1">
                                  <span className={isDark ? 'text-gray-400' : 'text-luxuryGreen-700/80 font-bold'}>{prod.category}</span>
                                  <span className="flex items-center gap-0.5 text-luxuryGold-500">
                                    <Star size={12} fill="currentColor" /> {prod.rating}
                                  </span>
                                </div>
                                <h3 
                                  onClick={() => { setSelectedProductId(prod.id); setActivePage('details'); }}
                                  className={`text-xs font-bold leading-snug cursor-pointer hover:text-luxuryGold-500 transition-colors ${
                                    isDark ? 'text-white' : 'text-luxuryGreen-950'
                                  }`}
                                >
                                  {prod.name}
                                </h3>
                                {viewMode === 'list' && (
                                  <p className="text-[10px] text-gray-500 leading-normal font-sans mt-2 max-w-xl">
                                    {prod.description}
                                  </p>
                                )}
                              </div>

                              <div className="flex justify-between items-center mt-4 pt-3 border-t border-luxuryGreen-950/20">
                                <span className="text-sm font-mono font-bold text-luxuryGold-500">₹{prod.price} <span className="text-[10px] text-gray-500 font-normal">/ 250g</span></span>
                                <button 
                                  onClick={() => handleAddToCart(prod.id, '250g', 1)}
                                  className={`font-mono text-[10px] font-bold px-3 py-1.5 rounded-lg transition-all flex items-center gap-1 active:scale-95 border ${
                                    isDark 
                                      ? 'bg-[#14221e] border-luxuryGreen-850 text-luxuryGold-500 hover:bg-luxuryGold-600 hover:text-luxuryGreen-950' 
                                      : 'bg-luxuryGreen-50 border-luxuryGreen-200 text-luxuryGreen-900 hover:bg-luxuryGold-600 hover:text-luxuryGreen-950'
                                  }`}
                                >
                                  <Plus size={12} /> Add
                                </button>
                              </div>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>

                </div>

              </div>
            )}

            {/* 3. PRODUCT DETAILS PAGE */}
            {activePage === 'details' && selectedProduct && (
              <div className="space-y-10">
                {/* Back button */}
                <button 
                  onClick={() => setActivePage('shop')}
                  className="flex items-center gap-1.5 text-xs font-mono text-gray-500 hover:text-luxuryGold-600"
                >
                  <ArrowLeft size={14} /> Back to Gourmet Catalog
                </button>

                <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
                  
                  {/* Left Column: Premium Interactive 3D Mockup Box */}
                  <div className="lg:col-span-5 flex flex-col gap-4">
                    {/* SVG 3D Packaging jar box preview */}
                    <div 
                      onMouseMove={(e) => {
                        const rect = e.currentTarget.getBoundingClientRect();
                        const x = e.clientX - rect.left - rect.width/2;
                        setRotationDegrees(Math.round(x * 0.2));
                      }}
                      onMouseLeave={() => setRotationDegrees(0)}
                      className={`rounded-3xl p-6 h-[380px] flex flex-col items-center justify-center relative cursor-grab overflow-hidden border shadow-md ${
                        isDark ? 'bg-[#060b09]/80 border-luxuryGreen-900' : 'bg-white border-gray-200 shadow-md'
                      }`}
                    >
                      <div className="absolute inset-0 bg-[linear-gradient(rgba(20,34,30,0.1)_1px,transparent_1px),linear-gradient(90deg,rgba(20,34,30,0.1)_1px,transparent_1px)] bg-[size:20px_20px] pointer-events-none" />
                      
                      <span className="absolute top-4 left-4 text-[9px] uppercase tracking-widest font-mono text-luxuryGold-500 font-bold bg-[#14221e] border border-luxuryGreen-850 px-2 py-1 rounded">
                        🖥️ INTERACTIVE 3D PACKAGE PREVIEW
                      </span>

                      {/* Animated SVG Container representing elegant glass jar/gold tin */}
                      <motion.svg 
                        animate={{ rotateY: rotationDegrees }}
                        transition={{ type: 'spring', damping: 20, stiffness: 100 }}
                        className="w-48 h-64 drop-shadow-[0_20px_35px_rgba(177,131,14,0.25)]" 
                        viewBox="0 0 200 300"
                      >
                        {/* Jar Top Lid (Golden wood finish) */}
                        <path d="M 40 30 C 40 20, 160 20, 160 30 L 160 50 C 160 60, 40 60, 40 50 Z" fill="url(#yellow-gold)" />
                        
                        {/* Glass Body Jar */}
                        <path d="M 42 50 C 42 50, 158 50, 158 50 L 158 260 C 158 280, 42 280, 42 260 Z" fill="rgba(20, 34, 30, 0.4)" stroke="rgba(177, 131, 14, 0.3)" strokeWidth="3" />
                        
                        {/* Gold Velvet Label */}
                        <rect x="50" y="100" width="100" height="90" rx="8" fill="#14221e" stroke="url(#yellow-gold)" strokeWidth="1.5" />
                        <text x="100" y="130" fill="#ffd700" fontSize="10" fontWeight="bold" textAnchor="middle" fontFamily="Playfair Display">NUCIS & CO.</text>
                        
                        <text x="100" y="150" fill="#ffffff" fontSize="7" textAnchor="middle" fontFamily="monospace">PREMIUM BOLD</text>
                        <text x="100" y="165" fill="#a0aec0" fontSize="6" textAnchor="middle" fontFamily="monospace">{selectedDetailWeight.toUpperCase()}</text>
                        
                        {/* Glow refraction highlight */}
                        <path d="M 50 60 L 50 250" stroke="rgba(255,255,255,0.06)" strokeWidth="4" />

                        {/* Content particles visible through jar (simulating nuts) */}
                        <circle cx="70" cy="220" r="10" fill="#d7b30f" opacity="0.6" />
                        <circle cx="100" cy="230" r="12" fill="#b89009" opacity="0.6" />
                        <circle cx="130" cy="210" r="10" fill="#7a540f" opacity="0.6" />
                        <circle cx="85" cy="245" r="9" fill="#d7b30f" opacity="0.6" />
                        <circle cx="115" cy="245" r="10" fill="#b89009" opacity="0.6" />
                      </motion.svg>

                      <p className="text-[10px] text-gray-550 font-mono mt-4">Move your cursor side-to-side to rotate the glass canister.</p>
                    </div>

                    {/* Small visual image gallery */}
                    <div className="grid grid-cols-2 gap-3">
                      <div 
                        onClick={() => setSelectedDetailImageIndex(0)}
                        className={`cursor-pointer rounded-xl overflow-hidden border-2 ${selectedDetailImageIndex === 0 ? 'border-luxuryGold-500' : 'border-transparent'}`}
                      >
                        <img src={selectedProduct.image} alt="gal 1" className="h-20 w-full object-cover" />
                      </div>
                      <div 
                        onClick={() => setSelectedDetailImageIndex(1)}
                        className={`cursor-pointer rounded-xl overflow-hidden border-2 ${selectedDetailImageIndex === 1 ? 'border-luxuryGold-500' : 'border-transparent'}`}
                      >
                        <img src="https://images.unsplash.com/photo-1595855759920-86582396756a?auto=format&fit=crop&q=80&w=300" alt="gal 2" className="h-20 w-full object-cover" />
                      </div>
                    </div>
                  </div>

                  {/* Right Column: Premium Gourmet Specifications */}
                  <div className="lg:col-span-7 space-y-6">
                    <div>
                      <span className="text-xs uppercase font-mono tracking-widest text-luxuryGold-500 font-semibold mb-1 block">Gourmet Selection</span>
                      <h2 className={`font-serif text-3xl md:text-4xl font-bold ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>{selectedProduct.name}</h2>
                      
                      <div className="flex items-center gap-4 mt-2 text-xs font-mono text-gray-400">
                        <span className="bg-[#0f1d19] border border-luxuryGreen-900 text-luxuryGold-500 px-2.5 py-0.5 rounded font-bold">
                          {selectedProduct.category}
                        </span>
                        <span className="flex items-center gap-0.5 text-luxuryGold-500 font-bold">
                          <Star size={13} fill="currentColor" /> {selectedProduct.rating} ({selectedProduct.reviewsCount} reviews)
                        </span>
                        <span>|</span>
                        <span className="text-emerald-400 font-semibold">✓ In Stock ({selectedProduct.inStock} units)</span>
                      </div>
                    </div>

                    <p className={`text-sm leading-relaxed font-sans border p-4 rounded-xl ${
                      isDark ? 'bg-[#0f1d19]/20 border-luxuryGreen-950 text-gray-300' : 'bg-white border-gray-200 text-gray-800 shadow-sm'
                    }`}>
                      {selectedProduct.description}
                    </p>

                    {/* Weight selector pills and calculated pricing */}
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 items-center py-4 border-y border-luxuryGreen-950/60">
                      <div>
                        <span className="text-[10px] uppercase font-mono tracking-wider font-bold text-luxuryGold-500 block mb-2">Select Gourmet Canister Weight</span>
                        <div className="flex gap-2 font-mono text-xs uppercase font-semibold">
                          {['250g', '500g', '1kg'].map((w) => (
                            <button 
                              key={w} 
                              onClick={() => setSelectedDetailWeight(w)}
                              className={`px-4 py-2 rounded-xl border transition-all ${
                                selectedDetailWeight === w 
                                  ? 'bg-luxuryGold-600 border-luxuryGold-500 text-luxuryGreen-950 font-bold' 
                                  : (isDark ? 'bg-luxuryGreen-950/30 border-luxuryGreen-900 text-gray-305 hover:bg-luxuryGreen-900' : 'bg-white border-gray-200 text-gray-650 hover:bg-gray-100')
                              }`}
                            >
                              {w}
                            </button>
                          ))}
                        </div>
                      </div>
                      
                      <div className="text-left sm:text-right font-mono">
                        <span className="text-[10px] uppercase tracking-wider text-gray-500 block mb-1">Calculated Gourmet Price</span>
                        <span className="text-2xl font-bold text-luxuryGold-500">
                          ₹{(() => {
                            let multiplier = 1;
                            if (selectedDetailWeight === '500g') multiplier = 1.9;
                            if (selectedDetailWeight === '1kg') multiplier = 3.5;
                            return Math.round(selectedProduct.price * multiplier);
                          })()}
                        </span>
                        <span className="text-[10px] text-gray-500 block font-sans mt-0.5">Includes 5% Central GST itemization.</span>
                      </div>
                    </div>

                    {/* Nutrition Accordion */}
                    <details className={`border rounded-xl p-4 cursor-pointer group shadow-sm ${
                      isDark ? 'bg-[#0f1d19]/25 border-luxuryGreen-900' : 'bg-white border-gray-200 shadow-sm'
                    }`}>
                      <summary className={`text-xs font-bold font-mono uppercase hover:text-luxuryGold-500 flex justify-between items-center outline-none list-none ${
                        isDark ? 'text-white' : 'text-luxuryGreen-950'
                      }`}>
                        <span>🧪 Dynamic Nutrition Facts (per 100g)</span>
                        <ChevronDown size={14} className="text-luxuryGold-500 group-open:rotate-180 transition-transform" />
                      </summary>
                      <div className="grid grid-cols-3 sm:grid-cols-6 gap-3 mt-4 pt-3 border-t border-luxuryGreen-950/20 text-center font-mono text-[10px]">
                        {Object.entries(selectedProduct.nutrition).map(([key, val]) => (
                          <div key={key} className={`border p-2 rounded-lg ${
                            isDark ? 'bg-[#0b1310] border-luxuryGreen-950' : 'bg-gray-50 border-gray-200/80 shadow-inner'
                          }`}>
                            <span className="text-gray-500 block uppercase">{key}</span>
                            <span className={`font-bold block mt-1 ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>{val}</span>
                          </div>
                        ))}
                      </div>
                    </details>

                    {/* Delivery Pin Code Estimate */}
                    <div className={`border p-4 rounded-2xl ${
                      isDark ? 'bg-luxuryGreen-950/20 border-luxuryGreen-950' : 'bg-white border-gray-200 shadow-sm'
                    }`}>
                      <span className="text-[10px] uppercase font-mono tracking-wider font-bold text-luxuryGold-500 block mb-2">Check Delivery Estimate & GST</span>
                      <form onSubmit={handleCheckPincode} className="flex gap-2 max-w-sm">
                        <input
                          type="text"
                          maxLength="6"
                          placeholder="Enter 6-digit Pincode"
                          value={pincodeCheck}
                          onChange={(e) => setPincodeCheck(e.target.value)}
                          className={`w-full text-xs rounded-xl px-3.5 py-2.5 focus:outline-none focus:border-luxuryGold-500 font-mono ${
                            isDark ? 'bg-[#0f1d19]/60 border-luxuryGreen-900 text-white' : 'bg-gray-50 border-gray-200 text-gray-805'
                          }`}
                        />
                        <button 
                          type="submit"
                          className="bg-[#14221e] border border-luxuryGreen-850 hover:bg-luxuryGold-600 hover:text-luxuryGreen-950 text-luxuryGold-500 font-mono font-bold px-4 py-2 rounded-xl text-xs transition-colors whitespace-nowrap active:scale-95"
                        >
                          Check
                        </button>
                      </form>
                      
                      {pincodeMessage && (
                        <p className={`text-[10px] mt-3 font-mono leading-relaxed ${pincodeMessage.type === 'success' ? 'text-emerald-500 font-semibold' : 'text-red-400'}`}>
                          {pincodeMessage.text}
                        </p>
                      )}
                    </div>

                    {/* Action buttons (Add to cart & Wishlist) */}
                    <div className="flex gap-4 pt-2">
                      <button 
                        onClick={() => handleAddToCart(selectedProduct.id, selectedDetailWeight, 1)}
                        className="flex-1 bg-gradient-to-r from-luxuryGold-600 to-luxuryGold-700 hover:from-luxuryGold-500 hover:to-luxuryGold-600 text-luxuryGreen-950 font-bold py-4 rounded-xl text-xs transition-all duration-300 shadow-lg hover:shadow-luxuryGold-500/20 flex items-center justify-center gap-2"
                      >
                        <ShoppingBag size={16} /> Add Gourmet Canister to Basket
                      </button>
                      
                      <button 
                        onClick={() => handleToggleWishlist(selectedProduct.id)}
                        className={`p-4 rounded-xl border flex items-center justify-center transition-colors ${
                          wishlist.includes(selectedProduct.id) 
                            ? 'bg-red-500/25 border-red-500 text-red-500' 
                            : (isDark ? 'bg-luxuryGreen-950/30 border-luxuryGreen-900 text-gray-400 hover:text-red-400' : 'bg-white border-gray-300 text-gray-500 hover:text-red-500 shadow-sm')
                        }`}
                      >
                        <Heart size={18} fill={wishlist.includes(selectedProduct.id) ? 'currentColor' : 'none'} />
                      </button>
                    </div>

                  </div>

                </div>

                {/* Related Products Grid */}
                <div className="space-y-6 pt-10 border-t border-luxuryGreen-950/60">
                  <h3 className={`text-xl font-serif font-bold ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>Related Wellness Selections</h3>
                  <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
                    {productsList.filter(p => p.id !== selectedProductId).slice(0, 4).map((prod) => (
                      <div 
                        key={prod.id} 
                        onClick={() => { setSelectedProductId(prod.id); setSelectedDetailWeight('250g'); }}
                        className={`cursor-pointer group relative rounded-xl border overflow-hidden transition-all duration-300 hover:-translate-y-1 shadow-sm ${
                          isDark ? 'bg-[#0f1d19]/20 border-luxuryGreen-900/60 hover:border-luxuryGold-500/30' : 'bg-white border-gray-200 hover:border-luxuryGold-500/30 shadow-sm'
                        }`}
                      >
                        <img src={prod.image} alt={prod.name} className="w-full h-36 object-cover" />
                        <div className="p-3">
                          <span className="text-[9px] uppercase font-mono text-luxuryGold-500 block mb-1">{prod.category}</span>
                          <h4 className={`text-xs font-bold truncate leading-tight ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>{prod.name}</h4>
                          <span className="text-[11px] font-mono text-luxuryGold-500 font-bold block mt-2">₹{prod.price}</span>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

              </div>
            )}

            {/* 4. CART & CHECKOUT PROCESS */}
            {activePage === 'checkout' && (
              <div className="space-y-8">
                
                {/* Visual Wizard status */}
                <div className={`flex justify-between items-center max-w-lg mx-auto border rounded-full px-6 py-3 font-mono text-[10px] uppercase font-bold ${
                  isDark ? 'bg-[#0b1310] border-luxuryGreen-900 text-gray-400' : 'bg-white border-gray-200 text-gray-600 shadow-sm'
                }`}>
                  <div className={`flex items-center gap-1.5 ${checkoutStep === 1 ? 'text-luxuryGold-500' : 'text-emerald-500'}`}>
                    <span>1. Shipping Address</span>
                    {checkoutStep > 1 && <CheckCircle size={12} />}
                  </div>
                  <div className="h-px bg-luxuryGreen-900 w-12" />
                  <div className={`flex items-center gap-1.5 ${checkoutStep === 2 ? 'text-luxuryGold-500 font-bold' : ''}`}>
                    <span>2. Gateway Payment</span>
                  </div>
                </div>

                {/* Wizard main contents */}
                <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                  
                  {/* Left Column (Address management / payment detail) */}
                  <div className="lg:col-span-2 space-y-6">
                    
                    {/* Step 1: Address Manager */}
                    {checkoutStep === 1 && (
                      <div className={`p-6 rounded-2xl border space-y-4 shadow-sm ${
                        isDark ? 'bg-luxuryGreen-950/20 border-luxuryGreen-900/60' : 'bg-white border-gray-200 shadow-md'
                      }`}>
                        <div className="flex justify-between items-center border-b border-luxuryGreen-950 pb-3">
                          <h2 className={`text-lg font-bold ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>Select Delivery Destination</h2>
                          <button 
                            onClick={() => setShowAddressForm(!showAddressForm)}
                            className="text-xs font-mono text-luxuryGold-600 hover:text-luxuryGold-500 flex items-center gap-1 font-bold"
                          >
                            <Plus size={14} /> Add New Address
                          </button>
                        </div>

                        {/* Add New Address Form */}
                        {showAddressForm && (
                          <form onSubmit={handleAddAddress} className="p-4 bg-[#0b1310]/80 border border-luxuryGreen-900 rounded-xl space-y-3 font-mono text-xs shadow-inner">
                            <div className="grid grid-cols-2 gap-3">
                              <div>
                                <label className="text-[9px] text-gray-500 uppercase font-semibold">Name</label>
                                <input 
                                  type="text" 
                                  required
                                  value={newAddress.name}
                                  onChange={(e) => setNewAddress({ ...newAddress, name: e.target.value })}
                                  className="w-full bg-[#14221e] border border-luxuryGreen-950 p-2 rounded text-white" 
                                />
                              </div>
                              <div>
                                <label className="text-[9px] text-gray-500 uppercase font-semibold">Phone</label>
                                <input 
                                  type="text" 
                                  required
                                  value={newAddress.phone}
                                  onChange={(e) => setNewAddress({ ...newAddress, phone: e.target.value })}
                                  className="w-full bg-[#14221e] border border-luxuryGreen-950 p-2 rounded text-white" 
                                />
                              </div>
                            </div>
                            <div>
                              <label className="text-[9px] text-gray-500 uppercase font-semibold">Street Address</label>
                              <input 
                                type="text" 
                                required
                                value={newAddress.address}
                                onChange={(e) => setNewAddress({ ...newAddress, address: e.target.value })}
                                className="w-full bg-[#14221e] border border-luxuryGreen-950 p-2 rounded text-white" 
                              />
                            </div>
                            <div className="grid grid-cols-3 gap-3">
                              <div>
                                <label className="text-[9px] text-gray-500 uppercase font-semibold">City</label>
                                <input 
                                  type="text" 
                                  required
                                  value={newAddress.city}
                                  onChange={(e) => setNewAddress({ ...newAddress, city: e.target.value })}
                                  className="w-full bg-[#14221e] border border-luxuryGreen-950 p-2 rounded text-white" 
                                />
                              </div>
                              <div>
                                <label className="text-[9px] text-gray-500 uppercase font-semibold">State</label>
                                <input 
                                  type="text" 
                                  required
                                  value={newAddress.state}
                                  onChange={(e) => setNewAddress({ ...newAddress, state: e.target.value })}
                                  className="w-full bg-[#14221e] border border-luxuryGreen-950 p-2 rounded text-white" 
                                />
                              </div>
                              <div>
                                <label className="text-[9px] text-gray-500 uppercase font-semibold">Pincode</label>
                                <input 
                                  type="text" 
                                  required
                                  value={newAddress.pincode}
                                  onChange={(e) => setNewAddress({ ...newAddress, pincode: e.target.value })}
                                  className="w-full bg-[#14221e] border border-luxuryGreen-950 p-2 rounded text-white" 
                                />
                              </div>
                            </div>
                            <div className="flex gap-2 justify-end pt-2">
                              <button 
                                type="button" 
                                onClick={() => setShowAddressForm(false)}
                                className="text-gray-400 px-3 py-1.5 hover:text-white"
                              >
                                Cancel
                              </button>
                              <button 
                                type="submit"
                                className="bg-luxuryGold-600 hover:bg-luxuryGold-500 text-luxuryGreen-950 font-bold px-4 py-1.5 rounded"
                              >
                                Save Location
                              </button>
                            </div>
                          </form>
                        )}

                        {/* List Address Cards */}
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                          {addresses.map((addr, idx) => (
                            <div 
                              key={addr.id}
                              onClick={() => setSelectedAddressIndex(idx)}
                              className={`cursor-pointer p-4 rounded-xl border flex flex-col justify-between relative transition-all duration-300 shadow-sm ${
                                selectedAddressIndex === idx 
                                  ? 'bg-[#0f1d19] border-luxuryGold-500' 
                                  : (isDark ? 'bg-luxuryGreen-950/10 border-luxuryGreen-950/60 hover:bg-luxuryGreen-950/30' : 'bg-gray-50 border-gray-200 hover:bg-gray-100 shadow-sm')
                              }`}
                            >
                              <div className="space-y-1">
                                <span className={`text-[9px] font-mono font-bold px-2 py-0.5 rounded border inline-block ${
                                  selectedAddressIndex === idx ? 'bg-luxuryGold-600 text-luxuryGreen-950 border-luxuryGold-500' : 'bg-luxuryGreen-900 border-luxuryGreen-850 text-luxuryGold-500'
                                }`}>
                                  {addr.type}
                                </span>
                                <h4 className={`text-xs font-bold pt-1 ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>{addr.name}</h4>
                                <p className="text-[10px] text-gray-500 font-sans leading-relaxed pt-1">
                                  {addr.address}, {addr.city}, {addr.state} - <span className="font-mono font-semibold">{addr.pincode}</span>
                                </p>
                              </div>
                              
                              <span className="text-[10px] font-mono text-gray-500 pt-3 block">{addr.phone}</span>
                              
                              {selectedAddressIndex === idx && (
                                <span className="absolute top-3 right-3 text-luxuryGold-500">
                                  <CheckCircle size={16} />
                                </span>
                              )}
                            </div>
                          ))}
                        </div>

                        {/* Complete address confirmation action */}
                        <button 
                          onClick={() => setCheckoutStep(2)}
                          className="w-full bg-gradient-to-r from-luxuryGold-600 to-luxuryGold-700 hover:from-luxuryGold-500 hover:to-luxuryGold-600 text-luxuryGreen-950 font-bold py-3 rounded-xl text-xs transition-all duration-300 shadow-md flex items-center justify-center gap-1.5"
                        >
                          Confirm & Proceed to Payment <ChevronRight size={14} />
                        </button>
                      </div>
                    )}

                    {/* Step 2: Payment Portal */}
                    {checkoutStep === 2 && (
                      <div className={`p-6 rounded-2xl border space-y-6 shadow-sm ${
                        isDark ? 'bg-luxuryGreen-950/20 border-luxuryGreen-900/60' : 'bg-white border-gray-200 shadow-md'
                      }`}>
                        <div className="border-b border-luxuryGreen-950 pb-3 flex items-center gap-2">
                          <button onClick={() => setCheckoutStep(1)} className="text-gray-400 hover:text-white pr-2"><ArrowLeft size={16} /></button>
                          <h2 className={`text-lg font-bold ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>Select Secure Gateway Method</h2>
                        </div>

                        {/* Select Method list */}
                        <div className="grid grid-cols-3 gap-3 font-mono text-[10px] uppercase font-bold text-center">
                          <div 
                            onClick={() => setPaymentMethod('upi')}
                            className={`cursor-pointer p-4 rounded-xl border flex flex-col items-center justify-center gap-2 transition-all ${
                              paymentMethod === 'upi' 
                                ? 'bg-[#0f1d19] border-luxuryGold-500 text-luxuryGold-500 font-bold shadow-md' 
                                : (isDark ? 'bg-luxuryGreen-950/15 border-luxuryGreen-950/60 hover:bg-luxuryGreen-950/30 text-gray-300' : 'bg-gray-50 border-gray-200 hover:bg-gray-100 text-gray-700')
                            }`}
                          >
                            <span className="text-3xl">📱</span>
                            <span>UPI (GPay/PhonePe)</span>
                          </div>
                          <div 
                            onClick={() => setPaymentMethod('card')}
                            className={`cursor-pointer p-4 rounded-xl border flex flex-col items-center justify-center gap-2 transition-all ${
                              paymentMethod === 'card' 
                                ? 'bg-[#0f1d19] border-luxuryGold-500 text-luxuryGold-500 font-bold shadow-md' 
                                : (isDark ? 'bg-luxuryGreen-950/15 border-luxuryGreen-950/60 hover:bg-luxuryGreen-950/30 text-gray-300' : 'bg-gray-50 border-gray-200 hover:bg-gray-100 text-gray-700')
                            }`}
                          >
                            <span className="text-3xl">💳</span>
                            <span>Credit/Debit Card</span>
                          </div>
                          <div 
                            onClick={() => setPaymentMethod('cod')}
                            className={`cursor-pointer p-4 rounded-xl border flex flex-col items-center justify-center gap-2 transition-all ${
                              paymentMethod === 'cod' 
                                ? 'bg-[#0f1d19] border-luxuryGold-500 text-luxuryGold-500 font-bold shadow-md' 
                                : (isDark ? 'bg-luxuryGreen-950/15 border-luxuryGreen-950/60 hover:bg-luxuryGreen-950/30 text-gray-300' : 'bg-gray-50 border-gray-200 hover:bg-gray-100 text-gray-700')
                            }`}
                          >
                            <span className="text-3xl">💵</span>
                            <span>Cash on Delivery</span>
                          </div>
                        </div>

                        {/* Razorpay Brand Highlight Box */}
                        <div className="p-4 bg-blue-950/30 border border-blue-900/60 rounded-xl flex items-center justify-between font-mono text-[10px]">
                          <div className="flex items-center gap-2">
                            <CreditCard className="text-blue-400" size={20} />
                            <div>
                              <span className="text-white font-bold block">Secure Razorpay Integration</span>
                              <span className="text-gray-400 block mt-0.5">UPI, Cards, and Netbanking are fully encrypted.</span>
                            </div>
                          </div>
                          <span className="text-[8px] bg-blue-900 text-blue-300 px-2 py-0.5 rounded font-mono font-bold">RAZORPAY SECURE</span>
                        </div>

                        {/* Payment Actions */}
                        <button 
                          onClick={handleCompleteOrder}
                          className="w-full bg-gradient-to-r from-luxuryGold-600 to-luxuryGold-700 hover:from-luxuryGold-500 hover:to-luxuryGold-600 text-luxuryGreen-950 font-bold py-3.5 rounded-xl text-xs transition-all duration-300 shadow-lg hover:shadow-luxuryGold-500/20 flex items-center justify-center gap-2 animate-bounce"
                        >
                          <Lock size={13} /> Complete Order & Transact ₹{cartTotal}
                        </button>
                      </div>
                    )}

                  </div>

                  {/* Right Column: Order Summary Basket */}
                  <div className="space-y-6">
                    <div className={`p-6 rounded-2xl border space-y-4 shadow-sm ${
                      isDark ? 'bg-[#0b1310] border-luxuryGreen-900' : 'bg-white border-gray-200 shadow-md'
                    }`}>
                      <h3 className="text-xs uppercase font-mono tracking-widest text-luxuryGold-500 font-bold border-b border-luxuryGreen-950 pb-2">Order Basket Summary</h3>
                      
                      {/* Calculations breakdown */}
                      <div className="space-y-2 border-b border-luxuryGreen-950/60 pb-3 text-xs font-mono text-gray-500">
                        <div className="flex justify-between">
                          <span>Subtotal</span>
                          <span className={isDark ? 'text-white' : 'text-gray-800 font-bold'}>₹{cartSubtotal}</span>
                        </div>
                        {discountAmount > 0 && (
                          <div className="flex justify-between text-emerald-500">
                            <span>Discount ({appliedCoupon?.code})</span>
                            <span>-₹{discountAmount}</span>
                          </div>
                        )}
                        <div className="flex justify-between">
                          <span>GST (5%)</span>
                          <span className={isDark ? 'text-white' : 'text-gray-800 font-bold'}>₹{gstAmount}</span>
                        </div>
                        <div className="flex justify-between">
                          <span>Delivery Charge</span>
                          <span className={isDark ? 'text-white' : 'text-gray-800 font-bold'}>{deliveryCharge === 0 ? 'FREE' : `₹${deliveryCharge}`}</span>
                        </div>
                      </div>

                      <div className="flex justify-between font-mono text-sm font-bold pt-1">
                        <span className={isDark ? 'text-white' : 'text-luxuryGreen-950'}>Total Amount</span>
                        <span className="text-luxuryGold-500 font-bold">₹{cartTotal}</span>
                      </div>
                    </div>
                  </div>

                </div>

                {/* Razorpay Gateway Simulation Modal */}
                <AnimatePresence>
                  {isProcessingPayment && (
                    <motion.div 
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      exit={{ opacity: 0 }}
                      className="fixed inset-0 z-50 bg-black/85 backdrop-blur-sm flex items-center justify-center p-6"
                    >
                      <div className="w-[380px] bg-[#0c100e] border border-blue-900 rounded-3xl p-6 text-center shadow-2xl relative font-sans space-y-6">
                        
                        {/* Razorpay logo header */}
                        <div className="flex justify-between items-center border-b border-gray-900 pb-3">
                          <span className="text-[10px] text-blue-400 font-mono font-bold tracking-widest">RAZORPAY CHECKOUT</span>
                          <span className="text-[9px] bg-blue-900/60 text-blue-300 px-2 py-0.5 rounded font-mono">SECURE</span>
                        </div>

                        {/* Spinner animation */}
                        <div className="py-6 flex flex-col items-center justify-center">
                          <div className="w-16 h-16 rounded-full border-4 border-t-blue-500 border-r-transparent border-b-transparent border-l-transparent animate-spin mb-4" />
                          <h3 className="text-base font-bold text-white font-mono">Authenticating Transaction...</h3>
                          <p className="text-xs text-gray-400 mt-2 font-mono">Authorizing UPI / Card request securely with RDS databases...</p>
                        </div>

                        {/* Amount */}
                        <div className="p-4 bg-luxuryGreen-950/40 border border-luxuryGreen-950 rounded-2xl">
                          <span className="text-[9px] text-gray-500 font-mono block">TRANSACTION AMOUNT</span>
                          <span className="text-2xl font-bold font-mono text-luxuryGold-500 block">₹{cartTotal}</span>
                        </div>

                        {/* Secure footer */}
                        <p className="text-[9px] text-gray-500 font-mono leading-relaxed">
                          Do not refresh this screen. Direct 256-bit SSL tunnels are established to route your payment settlement.
                        </p>

                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>

                {/* Animated Purchase Success Screen */}
                <AnimatePresence>
                  {isPaymentSuccess && recentOrderDetails && (
                    <motion.div 
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      exit={{ opacity: 0 }}
                      className="fixed inset-0 z-50 bg-[#09100d]/95 flex items-center justify-center p-6"
                    >
                      <div className="w-[450px] bg-[#0c1310] border border-luxuryGold-500/40 rounded-3xl p-8 text-center shadow-2xl relative font-sans space-y-6">
                        
                        {/* Animated Sparkle and checkmark */}
                        <div className="w-20 h-20 mx-auto rounded-full bg-gradient-to-tr from-luxuryGold-500 to-luxuryGold-600 flex items-center justify-center shadow-2xl relative">
                          <CheckCircle className="text-luxuryGreen-950 w-10 h-10" />
                          <Sparkles className="absolute -top-1 -right-1 text-white animate-bounce" />
                        </div>

                        <div className="space-y-2">
                          <span className="text-xs uppercase tracking-widest text-luxuryGold-500 font-mono font-bold block">TRANSACTION SUCCESSFUL</span>
                          <h2 className="text-2xl font-serif font-bold text-white">Your Wellness Journey Begins!</h2>
                          <p className="text-xs text-gray-300 leading-relaxed font-sans max-w-sm mx-auto">
                            Thank you for shopping with Nucis & Co. We have initiated hand-packing of your dry fruits and scheduled dispatch.
                          </p>
                        </div>

                        {/* Order breakdown card */}
                        <div className="p-5 bg-luxuryGreen-950/40 border border-luxuryGreen-950 rounded-2xl text-left font-mono text-xs space-y-2.5 shadow-inner">
                          <div className="flex justify-between border-b border-luxuryGreen-950 pb-1.5">
                            <span className="text-gray-500">Order ID</span>
                            <span className="text-white font-bold">{recentOrderDetails.id}</span>
                          </div>
                          <div className="flex justify-between border-b border-luxuryGreen-950 pb-1.5">
                            <span className="text-gray-500">Amount Charged</span>
                            <span className="text-luxuryGold-500 font-bold">₹{recentOrderDetails.amount}</span>
                          </div>
                          <div className="flex justify-between">
                            <span className="text-gray-500">Estimated Delivery</span>
                            <span className="text-emerald-400 font-semibold">{recentOrderDetails.deliveryDate}</span>
                          </div>
                        </div>

                        <div className="flex gap-4">
                          <button 
                            onClick={() => { setIsPaymentSuccess(false); setRecentOrderDetails(null); setActivePage('dashboard'); }}
                            className="flex-1 bg-luxuryGold-600 hover:bg-luxuryGold-500 text-luxuryGreen-950 font-bold py-3 rounded-xl text-xs transition-colors shadow-lg"
                          >
                            Track in Dashboard
                          </button>
                          <button 
                            onClick={() => { setIsPaymentSuccess(false); setRecentOrderDetails(null); setActivePage('shop'); }}
                            className="flex-1 bg-luxuryGreen-900 border border-luxuryGreen-850 hover:bg-luxuryGreen-850 text-luxuryGold-500 font-mono font-bold py-3 rounded-xl text-xs transition-colors"
                          >
                            Shop More
                          </button>
                        </div>

                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>

              </div>
            )}

            {/* 5. USER DASHBOARD */}
            {activePage === 'dashboard' && (
              <div className="space-y-6">
                
                {/* User Stats bar */}
                <div className={`border rounded-3xl p-6 flex flex-col md:flex-row justify-between items-center gap-6 shadow-md ${
                  isDark ? 'bg-gradient-to-r from-luxuryGreen-950 to-[#0c1310] border-luxuryGreen-900' : 'bg-gradient-to-r from-luxuryGreen-100 to-luxuryGreen-50 border-luxuryGreen-200'
                }`}>
                  <div className="flex items-center gap-4">
                    <div className="w-14 h-14 rounded-full bg-gradient-to-tr from-luxuryGold-500 to-luxuryGold-600 flex items-center justify-center font-serif text-xl font-bold text-luxuryGreen-950 shadow-lg">
                      SA
                    </div>
                    <div>
                      <h2 className={`text-xl font-bold ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>Shariff Ahmed</h2>
                      <span className="text-[10px] font-mono text-gray-550 uppercase tracking-widest">Premium Member since 2026</span>
                    </div>
                  </div>
                  
                  {/* Rewards tier badge */}
                  <div className={`border p-4 rounded-2xl flex items-center gap-3 font-mono text-xs shadow-inner ${
                    isDark ? 'bg-[#0b1310] border-luxuryGreen-950' : 'bg-white border-gray-200 shadow-sm'
                  }`}>
                    <span className="text-3xl">🏅</span>
                    <div>
                      <span className="text-[10px] text-gray-500 uppercase block">Gourmet Rewards Point Tier</span>
                      <span className="text-sm text-luxuryGold-500 font-bold block mt-0.5">{userPoints} points (Silver Wellness Tier)</span>
                    </div>
                  </div>
                </div>

                {/* Dashboard layout sections */}
                <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                  
                  {/* Left Column: Order timeline & wishlists */}
                  <div className="lg:col-span-2 space-y-6">
                    
                    {/* Orders list timeline */}
                    <div className={`p-6 rounded-2xl border space-y-6 shadow-sm ${
                      isDark ? 'bg-luxuryGreen-950/20 border-luxuryGreen-900/60' : 'bg-white border-gray-200 shadow-md'
                    }`}>
                      <h3 className="text-xs uppercase font-mono tracking-widest text-luxuryGold-500 font-bold border-b border-luxuryGreen-950 pb-2">Wellness Orders & Direct Invoices</h3>

                      {userOrders.map((ord) => (
                        <div key={ord.id} className={`p-4 border rounded-xl space-y-4 shadow-sm ${
                          isDark ? 'bg-[#0a0f0c] border-luxuryGreen-950' : 'bg-gray-50 border-gray-200'
                        }`}>
                          <div className="flex justify-between items-center text-xs font-mono">
                            <div>
                              <span className={`font-bold ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>{ord.id}</span>
                              <span className="text-gray-500 ml-2">Ordered on {ord.date}</span>
                            </div>
                            <span className="text-luxuryGold-500 font-bold">₹{ord.amount}</span>
                          </div>

                          <div className="text-[11px] text-gray-500">
                            {ord.items.map((item, idx) => (
                              <div key={idx} className="flex justify-between font-mono">
                                <span className={isDark ? 'text-gray-300' : 'text-gray-800'}>{item.name} ({item.weight}) x {item.quantity}</span>
                                <span className={isDark ? 'text-gray-305' : 'text-gray-900 font-semibold'}>₹{item.price * item.quantity}</span>
                              </div>
                            ))}
                          </div>

                          {/* Tracking Steps Bar */}
                          <div className="grid grid-cols-4 text-center font-mono text-[9px] text-gray-500 pt-2 border-t border-luxuryGreen-950/20">
                            <span className={ord.trackingStep >= 1 ? 'text-emerald-500 font-semibold' : ''}>Ordered</span>
                            <span className={ord.trackingStep >= 2 ? 'text-emerald-500 font-semibold' : ''}>Packed</span>
                            <span className={ord.trackingStep >= 3 ? 'text-emerald-500 font-semibold' : ''}>Out for Delivery</span>
                            <span className={ord.trackingStep >= 4 ? 'text-emerald-500 font-semibold' : ''}>Delivered</span>
                          </div>

                          <div className="flex justify-between items-center pt-2 text-[10px] font-mono text-gray-400">
                            <span>Est. Delivery: {ord.deliveryDate}</span>
                            <button 
                              onClick={() => alert(`Invoice ${ord.invoiceNo} successfully generated & downloaded! Total Amount charged: ₹${ord.amount}`)}
                              className="text-luxuryGold-600 hover:text-luxuryGold-500 font-bold hover:underline flex items-center gap-1"
                            >
                              📄 Download Invoice
                            </button>
                          </div>
                        </div>
                      ))}
                    </div>

                    {/* Persistent Wishlist Grid */}
                    <div className={`p-6 rounded-2xl border space-y-4 shadow-sm ${
                      isDark ? 'bg-luxuryGreen-950/20 border-luxuryGreen-900/60' : 'bg-white border-gray-200 shadow-md'
                    }`}>
                      <h3 className="text-xs uppercase font-mono tracking-widest text-luxuryGold-500 font-bold border-b border-luxuryGreen-950 pb-2">Active Wellness Wishlist</h3>
                      
                      {wishlist.length === 0 ? (
                        <p className="text-xs font-mono text-gray-500 text-center py-6">Your wishlist is currently empty. Explore our catalog!</p>
                      ) : (
                        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
                          {wishlist.map((id) => {
                            const prod = productsList.find(p => p.id === id);
                            if (!prod) return null;
                            return (
                              <div key={prod.id} className="p-3 bg-[#0a0f0c] border border-luxuryGreen-950 rounded-xl relative text-center shadow-sm">
                                <img src={prod.image} alt={prod.name} className="h-16 w-full object-cover rounded-lg mb-2 shadow-sm" />
                                <h4 className="text-[10px] font-bold truncate text-white">{prod.name}</h4>
                                <button 
                                  onClick={() => handleAddToCart(prod.id, '250g', 1)}
                                  className="mt-2 w-full bg-luxuryGold-600 text-luxuryGreen-950 font-bold text-[9px] py-1 rounded shadow-sm hover:bg-luxuryGold-500"
                                >
                                  Quick Add
                                </button>
                                <button 
                                  onClick={() => handleToggleWishlist(prod.id)}
                                  className="absolute top-2 right-2 text-red-500"
                                >
                                  <X size={12} />
                                </button>
                              </div>
                            );
                          })}
                        </div>
                      )}
                    </div>

                  </div>

                  {/* Right Column: Active Subscriptions */}
                  <div className="space-y-6">
                    
                    {/* Active Subscriptions */}
                    <div className={`p-6 rounded-2xl border space-y-4 shadow-sm ${
                      isDark ? 'bg-luxuryGreen-950/20 border-luxuryGreen-900/60' : 'bg-white border-gray-200 shadow-md'
                    }`}>
                      <h3 className="text-xs uppercase font-mono tracking-widest text-luxuryGold-500 font-bold border-b border-luxuryGreen-950 pb-2">Active Subscriptions</h3>
                      {userSubscriptions.map((sub) => (
                        <div key={sub.id} className={`p-4 border rounded-xl font-mono text-xs space-y-2 shadow-sm ${
                          isDark ? 'bg-[#0a0f0c] border-luxuryGreen-950' : 'bg-gray-50 border-gray-200'
                        }`}>
                          <div className="flex justify-between items-center">
                            <span className={`font-bold leading-tight truncate ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>{sub.name}</span>
                            <span className="text-[9px] bg-emerald-950 border border-emerald-800 text-emerald-400 px-2 py-0.5 rounded font-bold">
                              {sub.status}
                            </span>
                          </div>
                          
                          <div className="text-[10px] text-gray-500 space-y-0.5">
                            <div>Delivery Frequency: {sub.frequency} ({sub.weight})</div>
                            <div>Billing: ₹{sub.price} / cycle</div>
                            <div>Next Shipment: {sub.nextDate}</div>
                          </div>
                          
                          <button 
                            onClick={() => {
                              setUserSubscriptions(prev => prev.filter(s => s.id !== sub.id));
                              alert('Subscription successfully cancelled.');
                            }}
                            className="w-full text-center text-[10px] text-gray-550 hover:text-red-500 border border-luxuryGreen-950 py-1 rounded mt-2 hover:bg-red-500/10 transition-colors"
                          >
                            Cancel Subscription
                          </button>
                        </div>
                      ))}
                    </div>

                  </div>

                </div>

              </div>
            )}

            {/* 6. ADMIN DASHBOARD & 7. INVENTORY SYSTEM */}
            {activePage === 'admin' && (
              <div className="space-y-6">
                
                {/* Executive Analytics KPI Bar */}
                <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
                  {/* KPI card 1 */}
                  <div className={`p-5 border rounded-2xl font-mono shadow-sm ${
                    isDark ? 'bg-gradient-to-r from-luxuryGreen-950 to-[#0c1310] border-luxuryGreen-900' : 'bg-white border-gray-200 shadow-sm'
                  }`}>
                    <span className="text-[10px] text-gray-500 uppercase tracking-wider block">Net Revenue (Monthly)</span>
                    <div className="flex justify-between items-end mt-2">
                      <span className="text-2xl font-bold text-luxuryGold-500">₹8,42,500</span>
                      <span className="text-emerald-500 text-xs font-bold">+18.4%</span>
                    </div>
                  </div>
                  {/* KPI card 2 */}
                  <div className={`p-5 border rounded-2xl font-mono shadow-sm ${
                    isDark ? 'bg-gradient-to-r from-luxuryGreen-950 to-[#0c1310] border-luxuryGreen-900' : 'bg-white border-gray-200 shadow-sm'
                  }`}>
                    <span className="text-[10px] text-gray-500 uppercase tracking-wider block">Total Orders</span>
                    <div className="flex justify-between items-end mt-2">
                      <span className={`text-2xl font-bold ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>1,240</span>
                      <span className="text-emerald-500 text-xs font-bold">+12.2%</span>
                    </div>
                  </div>
                  {/* KPI card 3 */}
                  <div className={`p-5 border rounded-2xl font-mono shadow-sm ${
                    isDark ? 'bg-gradient-to-r from-luxuryGreen-950 to-[#0c1310] border-luxuryGreen-900' : 'bg-white border-gray-200 shadow-sm'
                  }`}>
                    <span className="text-[10px] text-gray-500 uppercase tracking-wider block">Average Order Value</span>
                    <div className="flex justify-between items-end mt-2">
                      <span className={`text-2xl font-bold ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>₹1,850</span>
                      <span className="text-emerald-500 text-xs font-bold">+4.1%</span>
                    </div>
                  </div>
                  {/* KPI card 4 */}
                  <div className={`p-5 border rounded-2xl font-mono shadow-sm ${
                    isDark ? 'bg-gradient-to-r from-luxuryGreen-950 to-[#0c1310] border-luxuryGreen-900' : 'bg-white border-gray-200 shadow-sm'
                  }`}>
                    <span className="text-[10px] text-gray-500 uppercase tracking-wider block">Cart Conversion Rate</span>
                    <div className="flex justify-between items-end mt-2">
                      <span className={`text-2xl font-bold ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>3.45%</span>
                      <span className="text-red-500 text-xs font-bold">-0.8%</span>
                    </div>
                  </div>
                </div>

                {/* Analytics graphs & batch inventory logs */}
                <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                  
                  {/* Left: Inventory System Batch Tracker */}
                  <div className={`p-6 border rounded-2xl space-y-4 shadow-sm ${
                    isDark ? 'bg-[#0c1310] border-luxuryGreen-900' : 'bg-white border-gray-200 shadow-md'
                  }`}>
                    <div className="flex justify-between items-center border-b border-luxuryGreen-950 pb-3">
                      <h2 className={`text-base font-bold flex items-center gap-1.5 ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>
                        <Package size={16} className="text-luxuryGold-500" /> Real-time Batch Inventory System
                      </h2>
                      <span className="text-[9px] bg-[#0f1d19] border border-luxuryGreen-900 text-luxuryGold-500 font-mono px-2 py-0.5 rounded font-bold">
                        AUDITED OK
                      </span>
                    </div>

                    <div className="overflow-x-auto">
                      <table className="w-full text-left font-mono text-[10px] border-collapse">
                        <thead>
                          <tr className={`border-b text-gray-500 ${isDark ? 'border-luxuryGreen-950' : 'border-gray-200 text-gray-655'}`}>
                            <th className="pb-3">PRODUCT</th>
                            <th className="pb-3">BATCH</th>
                            <th className="pb-3">EXPIRY</th>
                            <th className="pb-3 text-right">QUANTITY</th>
                            <th className="pb-3 text-right">PURCHASE PRICE</th>
                            <th className="pb-3 text-right">SELLING PRICE</th>
                          </tr>
                        </thead>
                        <tbody className={`divide-y text-gray-300 ${
                          isDark ? 'divide-luxuryGreen-950/30' : 'divide-gray-100'
                        }`}>
                          {productsList.map((prod) => (
                            <tr key={prod.id} className={`transition-colors ${
                              isDark ? 'hover:bg-luxuryGreen-950/20 text-gray-300' : 'hover:bg-gray-50 text-gray-700'
                            }`}>
                              <td className={`py-3 font-bold truncate max-w-[140px] ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>
                                {prod.name.split(' ')[0]} {prod.name.split(' ')[1]}
                              </td>
                              <td className="py-3">{prod.batchNo}</td>
                              <td className="py-3">
                                <span className="flex items-center gap-1">
                                  <Calendar size={10} className="text-luxuryGold-500" />
                                  <span>{prod.expiryDate}</span>
                                </span>
                              </td>
                              <td className={`py-3 text-right font-bold ${prod.inStock < 50 ? 'text-amber-500' : (isDark ? 'text-white' : 'text-gray-800')}`}>
                                {prod.inStock} units
                              </td>
                              <td className="py-3 text-right">₹{prod.purchasePrice}</td>
                              <td className="py-3 text-right text-luxuryGold-500 font-bold">₹{prod.price}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </div>

                  {/* Right: Vendor product approvals & orders management */}
                  <div className={`p-6 border rounded-2xl space-y-4 shadow-sm ${
                    isDark ? 'bg-[#0c1310] border-luxuryGreen-900' : 'bg-white border-gray-200 shadow-md'
                  }`}>
                    <h3 className="text-xs uppercase font-mono tracking-widest text-luxuryGold-500 font-bold border-b border-luxuryGreen-950 pb-2">Multi-Vendor Products Approvals</h3>
                    
                    {vendorProducts.map((vp) => (
                      <div 
                        key={vp.id} 
                        className={`p-4 border rounded-xl space-y-3 font-mono text-xs shadow-sm ${
                          isDark ? 'bg-[#0a0f0c] border-luxuryGreen-955' : 'bg-gray-50 border-gray-200'
                        }`}
                      >
                        <div className="flex justify-between items-start">
                          <div>
                            <span className="text-[10px] text-gray-500 block">VENDOR LISTING REQUEST</span>
                            <h4 className={`font-bold leading-tight mt-0.5 ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>{vp.name}</h4>
                          </div>
                          <span className={`text-[9px] px-2 py-0.5 rounded border font-bold ${
                            vp.status.includes('Pending') ? 'bg-amber-950 border-amber-900 text-amber-400' : 'bg-emerald-950 border-emerald-800 text-emerald-500'
                          }`}>
                            {vp.status}
                          </span>
                        </div>

                        <div className="flex justify-between text-[10px] text-gray-405">
                          <span>Quantity: {vp.quantity}</span>
                          <span>Unit Price: ₹{vp.price}</span>
                        </div>

                        {vp.status.includes('Pending') && (
                          <div className="flex gap-2 pt-2 border-t border-luxuryGreen-950/20">
                            <button 
                              onClick={() => {
                                setVendorProducts(prev => {
                                  return prev.map(p => p.id === vp.id ? { ...p, status: 'Approved & Active' } : p);
                                });
                                // Add to products list
                                setProductsList(prev => [
                                  ...prev,
                                  {
                                    id: 'fig-organic',
                                    name: vp.name,
                                    category: 'Dates',
                                    tag: 'New Organic Fig',
                                    price: vp.price,
                                    rating: 4.8,
                                    reviewsCount: 1,
                                    image: 'https://images.unsplash.com/photo-1569870499742-7a37f97b404a?auto=format&fit=crop&q=80&w=300',
                                    description: 'A premium, organic Turkish-imported fig selection rich in fiber and vitamins.',
                                    nutrition: { calories: '120 kcal', protein: '2g', fat: '0g', carbs: '28g', fiber: '6g', iron: '4% DV' },
                                    specs: { origin: 'Turkey', grade: 'Grade A', shelfLife: '6 Months', type: 'Raw figs' },
                                    inStock: 50,
                                    batchNo: 'B-FIG2026',
                                    expiryDate: '2026-11-20',
                                    purchasePrice: 400
                                  }
                                ]);
                                alert('Product successfully approved and integrated into Gourmet Shop catalog!');
                              }}
                              className="flex-1 bg-emerald-950 border border-emerald-800 hover:bg-emerald-800 text-emerald-400 font-mono font-bold py-1.5 rounded text-[10px]"
                            >
                              Approve & Publish
                            </button>
                            <button 
                              onClick={() => {
                                setVendorProducts(prev => prev.filter(p => p.id !== vp.id));
                                alert('Product listing request rejected.');
                              }}
                              className="text-gray-500 hover:text-red-400 py-1 text-[10px]"
                            >
                              Reject
                            </button>
                          </div>
                        )}
                      </div>
                    ))}
                  </div>

                </div>

              </div>
            )}

            {/* 8. VENDOR PORTAL */}
            {activePage === 'vendor' && (
              <div className="space-y-6">
                
                {/* Header overview */}
                <div className={`border rounded-3xl p-6 flex flex-col md:flex-row justify-between items-center gap-6 shadow-md ${
                  isDark ? 'bg-gradient-to-r from-luxuryGreen-950 to-[#0c1310] border-luxuryGreen-900' : 'bg-gradient-to-r from-luxuryGreen-100 to-luxuryGreen-50 border-luxuryGreen-200'
                }`}>
                  <div>
                    <h2 className={`text-xl font-bold ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>Aura Farms Sourcing Portal</h2>
                    <span className="text-[10px] font-mono text-gray-500 uppercase tracking-widest">Supplier ID: VND-22910</span>
                  </div>
                  <div className="flex gap-4 font-mono text-xs">
                    <div className={`border px-4 py-2.5 rounded-xl shadow-sm ${isDark ? 'bg-[#0b1310] border-luxuryGreen-950' : 'bg-white border-gray-200'}`}>
                      <span className="text-[9px] text-gray-500 block uppercase">Settled Balance</span>
                      <span className="text-sm text-emerald-500 font-bold block mt-0.5">₹43,250</span>
                    </div>
                    <div className={`border px-4 py-2.5 rounded-xl shadow-sm ${isDark ? 'bg-[#0b1310] border-luxuryGreen-950' : 'bg-white border-gray-200'}`}>
                      <span className="text-[9px] text-gray-500 block uppercase">Outstanding Settlements</span>
                      <span className="text-sm text-amber-500 font-bold block mt-0.5">₹18,750</span>
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                  
                  {/* Left Column: Upload New Stock Form */}
                  <div className={`p-6 rounded-2xl border space-y-4 shadow-sm ${
                    isDark ? 'bg-luxuryGreen-950/20 border-luxuryGreen-900/60' : 'bg-white border-gray-200 shadow-md'
                  }`}>
                    <h3 className="text-xs uppercase font-mono tracking-widest text-luxuryGold-500 font-bold border-b border-luxuryGreen-950 pb-2">Upload Dry Fruit Stock Request</h3>
                    
                    <form 
                      onSubmit={(e) => {
                        e.preventDefault();
                        const fd = new FormData(e.currentTarget);
                        const newStockRequest = {
                          id: `V-${Math.floor(100+Math.random()*900)}`,
                          name: fd.get('prodName'),
                          price: Number(fd.get('price')),
                          status: 'Pending Approval',
                          quantity: `${fd.get('qty')}kg`,
                          date: 'May 25, 2026'
                        };
                        setVendorProducts(prev => [newStockRequest, ...prev]);
                        e.currentTarget.reset();
                        alert('Stock approval request successfully submitted to executive admin!');
                      }}
                      className="space-y-3 font-mono text-xs"
                    >
                      <div>
                        <label className="text-[9px] text-gray-500 uppercase font-semibold">Dry Fruit Title</label>
                        <input name="prodName" required placeholder="e.g. Organic Figs" className={`w-full border p-2.5 rounded ${
                          isDark ? 'bg-[#14221e] border-luxuryGreen-950 text-white' : 'bg-gray-50 border-gray-200 text-gray-800'
                        }`} />
                      </div>
                      <div className="grid grid-cols-2 gap-3">
                        <div>
                          <label className="text-[9px] text-gray-500 uppercase font-semibold">Gourmet Selling Price (per 250g)</label>
                          <input name="price" type="number" required placeholder="₹500" className={`w-full border p-2.5 rounded ${
                            isDark ? 'bg-[#14221e] border-luxuryGreen-950 text-white' : 'bg-gray-50 border-gray-200 text-gray-800'
                          }`} />
                        </div>
                        <div>
                          <label className="text-[9px] text-gray-500 uppercase font-semibold">Stock Quantity (kg)</label>
                          <input name="qty" type="number" required placeholder="50" className={`w-full border p-2.5 rounded ${
                            isDark ? 'bg-[#14221e] border-luxuryGreen-950 text-white' : 'bg-gray-50 border-gray-200 text-gray-800'
                          }`} />
                        </div>
                      </div>
                      <button 
                        type="submit"
                        className="w-full bg-gradient-to-r from-luxuryGold-600 to-luxuryGold-700 text-luxuryGreen-950 font-bold py-2.5 rounded-xl text-xs transition-colors mt-2"
                      >
                        Submit Stock Request
                      </button>
                    </form>
                  </div>

                  {/* Right Column: Settlement transactions list */}
                  <div className={`p-6 border rounded-2xl space-y-4 shadow-sm ${
                    isDark ? 'bg-[#0c1310] border-luxuryGreen-900' : 'bg-white border-gray-200 shadow-md'
                  }`}>
                    <h3 className="text-xs uppercase font-mono tracking-widest text-luxuryGold-500 font-bold border-b border-luxuryGreen-950 pb-2">Supplier Settlement Records</h3>
                    <div className="space-y-3 font-mono text-xs">
                      {vendorSettlements.map((set) => (
                        <div 
                          key={set.id} 
                          className={`p-3 border rounded-xl flex justify-between items-center shadow-sm ${
                            isDark ? 'bg-[#0a0f0c] border-luxuryGreen-950' : 'bg-gray-50 border-gray-200/80'
                          }`}
                        >
                          <div>
                            <span className="text-[9px] text-gray-500 block">SETTLEMENT REF: {set.id}</span>
                            <span className={`font-bold block mt-0.5 ${isDark ? 'text-white' : 'text-luxuryGreen-950'}`}>Processed on {set.date}</span>
                          </div>
                          
                          <div className="text-right">
                            <span className="text-luxuryGold-500 font-bold block">₹{set.amount}</span>
                            <span className={`text-[9px] font-bold ${set.status === 'Settled' ? 'text-emerald-500' : 'text-amber-500'}`}>
                              {set.status}
                            </span>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>

                </div>

              </div>
            )}

            {/* 10. AWS ARCHITECTURE SCREEN */}
            {activePage === 'aws' && (
              <AWSVisualizer />
            )}

          </motion.div>
        </AnimatePresence>
      </main>

    </div>
  );
}
