import React, { useState, useRef, useEffect } from 'react';
import { MessageSquare, X, Send, Sparkles, PlusCircle, Check } from 'lucide-react';

export default function Chatbot({ onAddToCart }) {
  const [isOpen, setIsOpen] = useState(false);
  const [messages, setMessages] = useState([
    {
      id: 1,
      sender: 'ai',
      text: "Welcome to Nucis & Co. LuxeAI Assistant! 🌟 I'm here to provide premium wellness recommendations, nutrition facts, and recipes. Try asking me: 'Which nuts are best for brain health?' or just type 'Add 250g Almonds to cart' to shop immediately!"
    }
  ]);
  const [inputText, setInputText] = useState('');
  const messagesEndRef = useRef(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages, isOpen]);

  const handleSend = () => {
    if (!inputText.trim()) return;

    const userMsg = {
      id: Date.now(),
      sender: 'user',
      text: inputText
    };

    setMessages(prev => [...prev, userMsg]);
    setInputText('');

    // Generate intelligent AI response based on keywords
    setTimeout(() => {
      const reply = getAIResponse(inputText.toLowerCase());
      const aiMsg = {
        id: Date.now() + 1,
        sender: 'ai',
        text: reply.text,
        action: reply.action
      };
      setMessages(prev => [...prev, aiMsg]);
    }, 800);
  };

  const getAIResponse = (input) => {
    // Check if adding to cart
    if (input.includes('add') && (input.includes('almond') || input.includes('badam') || input.includes('cashew') || input.includes('kaju') || input.includes('walnut') || input.includes('akhrot') || input.includes('pista') || input.includes('pistachio') || input.includes('date') || input.includes('seeds') || input.includes('hamper') || input.includes('box'))) {
      let productKey = '';
      let productName = '';
      let weight = '250g';

      if (input.includes('500g')) weight = '500g';
      if (input.includes('1kg') || input.includes('1 kg')) weight = '1kg';

      if (input.includes('almond') || input.includes('badam')) {
        productKey = 'almonds-premium';
        productName = 'Premium California Almonds';
      } else if (input.includes('cashew') || input.includes('kaju')) {
        productKey = 'cashews-royal';
        productName = 'Royal Mangalore Cashews';
      } else if (input.includes('walnut') || input.includes('akhrot')) {
        productKey = 'walnuts-kashmiri';
        productName = 'Kashmiri Snow-White Walnuts';
      } else if (input.includes('pista') || input.includes('pistachio')) {
        productKey = 'pistachios-iranian';
        productName = 'Iranian Saffron Pistachios';
      } else if (input.includes('date')) {
        productKey = 'dates-medjool';
        productName = 'Imperial Medjool Dates';
      } else if (input.includes('seeds')) {
        productKey = 'seeds-superfood';
        productName = 'Superfood Omega Seed Mix';
      } else {
        productKey = 'gift-festive-gold';
        productName = 'Aura Festive Gold Box';
      }

      // Execute Cart action!
      if (onAddToCart) {
        onAddToCart(productKey, weight);
      }

      return {
        text: `✨ Absolutely! I have successfully added the **${productName} (${weight})** directly to your floating cart drawer. Let me know if you would like to proceed to checkout or look for something else!`,
        action: { type: 'add_to_cart', productName, weight }
      };
    }

    if (input.includes('brain') || input.includes('memory') || input.includes('focus')) {
      return {
        text: "🧠 For supreme brain health and focus, I highly recommend our **Snow-White Kashmiri Walnuts (Akhrot)** and **Premium California Almonds (Badam)**. Walnuts are packed with Omega-3 fatty acids (alpha-linolenic acid), which shield neural pathways, while almonds are rich in Vitamin E, which supports memory retention!"
      };
    }

    if (input.includes('recipe') || input.includes('shake') || input.includes('smoothie') || input.includes('eat')) {
      return {
        text: "🥤 **LuxeAI Signature Energy Almond Shake Recipe:**\n\n1. Soak 10 **Premium California Almonds** overnight.\n2. Peel them and blend with 1 organic banana, 2 **Medjool Dates** (for natural gold caramel sweetening), and 250ml milk/almond milk.\n3. Sprinkle a tablespoon of our **Omega Seed Mix** on top.\n\nThis shake provides 15g of organic plant protein and clean brain energy for the entire day!"
      };
    }

    if (input.includes('skin') || input.includes('hair') || input.includes('anti-aging')) {
      return {
        text: "✨ To nourish your skin and hair, our **Saffron-Infused Iranian Pistachios** are packed with antioxidants, copper, and vitamin E. Combined with the Omega-3 rich **7-in-1 Seed Mix**, they promote natural collagen production and a beautiful radiant glow!"
      };
    }

    if (input.includes('heart') || input.includes('cholesterol')) {
      return {
        text: "❤️ For cardiovascular health, **Royal Mangalore Cashews** and **Omega Seeds** are excellent. They are rich in monounsaturated fats (oleic acid) which support healthy LDL cholesterol levels and optimize heart muscle elasticity."
      };
    }

    if (input.includes('discount') || input.includes('offer') || input.includes('promo')) {
      return {
        text: "🎁 Exclusive LuxeAI Offer: Use code **LUXURYHEALTH** at checkout for a special **15% discount** on your premium wellness order (orders above ₹1000). Enter the code in your cart drawer to see instant savings!"
      };
    }

    // Default reply
    return {
      text: "🌿 Thank you for reaching out! Nucis & Co. dry fruits are handpicked and triple-sorted to guarantee maximum sizing and optimal nutrient lock. \n\nTell me: Are you looking for health recommendations (brain, heart, skin), weight-specific nutrition info, or a customized seed recipe?"
    };
  };

  return (
    <div className="fixed bottom-6 right-6 z-50 font-sans">
      {/* Floating Circle Button */}
      {!isOpen && (
        <button
          onClick={() => setIsOpen(true)}
          className="relative flex items-center justify-center w-14 h-14 bg-gradient-to-r from-luxuryGold-600 to-luxuryGold-700 hover:from-luxuryGold-500 hover:to-luxuryGold-600 rounded-full shadow-2xl transition-all duration-300 hover:scale-110 group border border-luxuryGold-400/30"
          style={{ boxShadow: '0 8px 30px rgba(177, 131, 14, 0.4)' }}
        >
          <Sparkles className="absolute top-1 right-1 w-4 h-4 text-white animate-bounce" />
          <MessageSquare className="w-6 h-6 text-white group-hover:rotate-12 transition-transform" />
        </button>
      )}

      {/* Chat Window Box */}
      {isOpen && (
        <div 
          className="w-[360px] h-[480px] bg-[#0c1310]/95 backdrop-blur-md border border-luxuryGreen-800 rounded-2xl shadow-2xl flex flex-col overflow-hidden transition-all duration-300"
          style={{ boxShadow: '0 12px 50px rgba(0,0,0,0.6)' }}
        >
          {/* Header */}
          <div className="bg-gradient-to-r from-[#14221e] to-[#0c1310] border-b border-luxuryGreen-900 p-4 flex justify-between items-center">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-full bg-gradient-to-tr from-luxuryGold-500 to-luxuryGold-600 flex items-center justify-center shadow-lg">
                <Sparkles size={16} className="text-[#14221e]" />
              </div>
              <div>
                <h3 className="text-sm font-bold text-white leading-none">LuxeAI Wellness</h3>
                <span className="text-[9px] text-emerald-400 font-mono tracking-widest uppercase mt-0.5 block">Nucis & Co. Expert</span>
              </div>
            </div>
            <button 
              onClick={() => setIsOpen(false)}
              className="text-gray-400 hover:text-white hover:bg-white/10 p-1.5 rounded-full transition-colors"
            >
              <X size={16} />
            </button>
          </div>

          {/* Messages Body */}
          <div className="flex-1 p-4 overflow-y-auto space-y-3 bg-[#060a08]/90">
            {messages.map((msg) => (
              <div 
                key={msg.id} 
                className={`flex ${msg.sender === 'user' ? 'justify-end' : 'justify-start'}`}
              >
                <div 
                  className={`max-w-[85%] p-3 rounded-2xl text-xs leading-relaxed font-sans shadow-md ${
                    msg.sender === 'user'
                      ? 'bg-luxuryGold-600 text-luxuryGreen-950 font-semibold rounded-tr-none'
                      : 'bg-[#14221e] text-gray-200 border border-luxuryGreen-900/60 rounded-tl-none whitespace-pre-line'
                  }`}
                >
                  {msg.text}

                  {msg.action && msg.action.type === 'add_to_cart' && (
                    <div className="mt-2 flex items-center gap-1 text-[10px] bg-emerald-950 border border-emerald-800 text-emerald-400 p-1.5 rounded-lg font-mono">
                      <Check size={12} />
                      <span>Added {msg.action.productName} ({msg.action.weight})</span>
                    </div>
                  )}
                </div>
              </div>
            ))}
            <div ref={messagesEndRef} />
          </div>

          {/* Quick recommendations chips */}
          <div className="px-4 py-2 border-t border-luxuryGreen-950/60 flex gap-1.5 overflow-x-auto bg-[#070b09] scrollbar-none">
            <button 
              onClick={() => setInputText('What is best for brain health?')}
              className="flex-shrink-0 text-[10px] bg-[#14221e] hover:bg-luxuryGreen-900 text-luxuryGold-500 font-mono px-2 py-1 rounded-full border border-luxuryGreen-800 transition-colors"
            >
              🧠 Brain Health
            </button>
            <button 
              onClick={() => setInputText('Give me an energy shake recipe')}
              className="flex-shrink-0 text-[10px] bg-[#14221e] hover:bg-luxuryGreen-900 text-luxuryGold-500 font-mono px-2 py-1 rounded-full border border-luxuryGreen-800 transition-colors"
            >
              🥤 Recipe Shake
            </button>
            <button 
              onClick={() => setInputText('Add 500g Cashews to my cart')}
              className="flex-shrink-0 text-[10px] bg-[#14221e] hover:bg-luxuryGreen-900 text-luxuryGold-500 font-mono px-2 py-1 rounded-full border border-luxuryGreen-800 transition-colors"
            >
              🛒 Quick Add Cashews
            </button>
          </div>

          {/* Inputs Bar */}
          <div className="p-3 border-t border-luxuryGreen-900 bg-[#0c1310] flex gap-2 items-center">
            <input
              type="text"
              value={inputText}
              onChange={(e) => setInputText(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleSend()}
              placeholder="Ask for dry fruit recipes, health info..."
              className="flex-1 bg-[#14221e] border border-luxuryGreen-900 text-white rounded-full px-4 py-2 text-xs focus:outline-none focus:border-luxuryGold-500 font-sans"
            />
            <button 
              onClick={handleSend}
              className="w-8 h-8 rounded-full bg-luxuryGold-600 hover:bg-luxuryGold-500 text-luxuryGreen-950 flex items-center justify-center shadow-lg transition-transform hover:scale-105"
            >
              <Send size={14} className="ml-0.5" />
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
