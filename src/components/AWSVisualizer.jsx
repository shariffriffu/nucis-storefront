import React, { useState } from 'react';
import { 
  Cloud, 
  Cpu, 
  Database, 
  HardDrive, 
  Layers, 
  Activity, 
  Info,
  Server,
  Shuffle,
  ShieldCheck
} from 'lucide-react';

export default function AWSVisualizer() {
  const [selectedNode, setSelectedNode] = useState(null);

  const nodes = [
    {
      id: 'cloudfront',
      name: 'Amazon CloudFront CDN',
      icon: Cloud,
      color: '#ff9900',
      x: 10,
      y: 50,
      description: 'Global Content Delivery Network caching static assets (images, React app bundles) globally at edge locations for millisecond loading times.',
      details: {
        'Edge Locations': '200+ globally',
        'TTL Protocol': 'Optimized S3 Caching',
        'SSL Provider': 'AWS Certificate Manager (ACM)',
        'HTTP Version': 'HTTP/3 Support'
      }
    },
    {
      id: 'alb',
      name: 'Application Load Balancer',
      icon: Shuffle,
      color: '#8C4FFF',
      x: 25,
      y: 50,
      description: 'Distributes incoming application traffic across multiple backend targets (EC2 nodes) in different Availability Zones to ensure high availability and fault tolerance.',
      details: {
        'Type': 'Layer 7 Load Balancer',
        'Target Groups': 'business-backend-tg',
        'Health Check Path': '/api/health',
        'Idle Timeout': '60 seconds'
      }
    },
    {
      id: 'ec2',
      name: 'EC2 Backend (NestJS Server)',
      icon: Cpu,
      color: '#FF4F4F',
      x: 45,
      y: 50,
      description: 'Host for backend NestJS REST API. Configured on an Ubuntu Server with Nginx reverse-proxy and PM2 process management.',
      details: {
        'Instance Name': 'business-backend-server',
        'Instance Type': 't3.medium (2 vCPU, 4GB RAM)',
        'OS': 'Ubuntu Server 22.04 LTS',
        'PM2 Process': 'business-api',
        'Reverse Proxy': 'Nginx (Ports 80/443)',
        'Local API Port': '5000'
      }
    },
    {
      id: 'rds',
      name: 'RDS PostgreSQL Database',
      icon: Database,
      color: '#3366ff',
      x: 70,
      y: 30,
      description: 'Highly available relational database hosting dry fruit stocks, user profile information, inventory logs, and order histories.',
      details: {
        'Engine': 'PostgreSQL v15',
        'Database Name': 'businessdb',
        'Username': 'admin',
        'Multi-AZ': 'Enabled (Failover support)',
        'Backup Retention': '7 Days (Auto-backups)'
      }
    },
    {
      id: 'redis',
      name: 'ElastiCache Redis',
      icon: Layers,
      color: '#dc3545',
      x: 70,
      y: 70,
      description: 'In-memory data store acting as a high-speed cache for catalog filters, AI recommendation results, active user sessions, and shopping cart values.',
      details: {
        'Engine': 'Redis OSS Cluster',
        'Instance Type': 'cache.t3.micro',
        'Node Count': '1 Master, 1 Replica',
        'Avg. Latency': '< 1 millisecond'
      }
    },
    {
      id: 's3',
      name: 'Amazon S3 Bucket',
      icon: HardDrive,
      color: '#4caf50',
      x: 45,
      y: 15,
      description: 'Simple Storage Service for hosting high-resolution product media, dry fruit packaging assets, and downloadable invoice PDFs.',
      details: {
        'Bucket Name': 'nucis-storefront-assets',
        'Storage Class': 'S3 Standard',
        'CORS Policy': 'Configured for frontend domain',
        'Encryption': 'SSE-S3 enabled'
      }
    },
    {
      id: 'monitoring',
      name: 'CloudWatch & Monitoring',
      icon: Activity,
      color: '#00bcd4',
      x: 90,
      y: 50,
      description: 'Unified monitoring dashboard tracking EC2 CPU utilization, RDS connection counts, ElastiCache memory usage, and alerting PM2 process health.',
      details: {
        'Alarms': 'CPU > 80%, RDS Connections > 200',
        'Log Groups': '/aws/ec2/business-backend',
        'Metrics Interval': '1 Minute (Detailed)',
        'Alerting': 'Amazon SNS to Telegram/Slack'
      }
    }
  ];

  return (
    <div className="p-6 bg-[#09100d] border border-luxuryGreen-900 rounded-2xl relative overflow-hidden shadow-2xl">
      {/* Grid Overlay */}
      <div className="absolute inset-0 bg-[linear-gradient(rgba(20,34,30,0.2)_1px,transparent_1px),linear-gradient(90deg,rgba(20,34,30,0.2)_1px,transparent_1px)] bg-[size:30px_30px]pointer-events-none" />

      {/* Header */}
      <div className="relative z-10 flex flex-col md:flex-row justify-between items-start md:items-center mb-8 border-b border-luxuryGreen-950 pb-4">
        <div>
          <span className="text-xs uppercase tracking-widest text-luxuryGold-500 font-semibold mb-1 block">Infrastructure Map</span>
          <h2 className="text-2xl font-bold text-white flex items-center gap-2">
            AWS Multi-Tier Architecture <span className="text-xs bg-emerald-950 border border-emerald-800 text-emerald-400 px-2 py-0.5 rounded-full font-mono">LIVE FLOW</span>
          </h2>
          <p className="text-xs text-gray-400 mt-1">Interactive schematic detailing request routing, caching layers, and database clusters.</p>
        </div>
        <div className="flex items-center gap-2 mt-3 md:mt-0 text-xs bg-luxuryGreen-950/60 border border-luxuryGreen-900/60 p-2 rounded-lg text-gray-300">
          <Info size={14} className="text-luxuryGold-500" />
          <span>Click any component to inspect AWS specifications.</span>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 relative z-10">
        {/* SVG Topology Screen */}
        <div className="lg:col-span-2 bg-[#060b09]/80 border border-luxuryGreen-950 rounded-xl p-4 flex items-center justify-center min-h-[400px] relative">
          <svg className="w-full h-[400px]" viewBox="0 0 1000 500">
            {/* Defs for gradients & glowing */}
            <defs>
              <filter id="glow" x="-20%" y="-20%" width="140%" height="140%">
                <feGaussianBlur stdDeviation="4" result="blur" />
                <feMerge>
                  <feMergeNode in="blur" />
                  <feMergeNode in="SourceGraphic" />
                </feMerge>
              </filter>
              <linearGradient id="yellow-gold" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stopColor="#ffd700" />
                <stop offset="100%" stopColor="#b1830e" />
              </linearGradient>
            </defs>

            {/* Connecting paths */}
            {/* CloudFront -> ALB */}
            <path d="M 150 250 L 250 250" stroke="rgba(140, 79, 255, 0.4)" strokeWidth="3" strokeDasharray="5,5" />
            
            {/* ALB -> EC2 */}
            <path d="M 310 250 L 450 250" stroke="rgba(255, 79, 79, 0.4)" strokeWidth="3" />
            
            {/* EC2 -> S3 */}
            <path d="M 490 220 L 490 120" stroke="rgba(76, 175, 80, 0.4)" strokeWidth="3" />

            {/* EC2 -> RDS */}
            <path d="M 530 240 L 700 150" stroke="rgba(51, 102, 255, 0.4)" strokeWidth="3" />

            {/* EC2 -> Redis */}
            <path d="M 530 260 L 700 350" stroke="rgba(220, 53, 69, 0.4)" strokeWidth="3" />

            {/* Database Sync to Monitoring */}
            <path d="M 770 150 L 900 230" stroke="rgba(0, 188, 212, 0.3)" strokeWidth="2" strokeDasharray="4,4" />
            <path d="M 770 350 L 900 270" stroke="rgba(0, 188, 212, 0.3)" strokeWidth="2" strokeDasharray="4,4" />
            
            {/* EC2 to Monitoring */}
            <path d="M 530 250 L 900 250" stroke="rgba(0, 188, 212, 0.3)" strokeWidth="2" strokeDasharray="4,4" />

            {/* Animated Packet flows */}
            {/* Packet 1: CF -> ALB */}
            <circle r="5" fill="#ff9900" filter="url(#glow)">
              <animateMotion dur="2.5s" repeatCount="indefinite" path="M 150 250 L 250 250" />
            </circle>

            {/* Packet 2: ALB -> EC2 */}
            <circle r="5" fill="#8C4FFF" filter="url(#glow)">
              <animateMotion dur="2s" repeatCount="indefinite" path="M 310 250 L 450 250" />
            </circle>

            {/* Packet 3: EC2 -> RDS */}
            <circle r="4" fill="#3366ff" filter="url(#glow)">
              <animateMotion dur="3s" repeatCount="indefinite" path="M 530 240 L 700 150" />
            </circle>

            {/* Packet 4: EC2 -> Redis */}
            <circle r="4" fill="#dc3545" filter="url(#glow)">
              <animateMotion dur="1.5s" repeatCount="indefinite" path="M 530 260 L 700 350" />
            </circle>

            {/* Node Render */}
            {nodes.map((node) => {
              const Icon = node.icon;
              const isSelected = selectedNode?.id === node.id;
              const xPos = (node.x / 100) * 1000;
              const yPos = (node.y / 100) * 500;

              return (
                <g 
                  key={node.id} 
                  transform={`translate(${xPos - 40}, ${yPos - 40})`}
                  onClick={() => setSelectedNode(node)}
                  className="cursor-pointer"
                >
                  {/* Outer glow when selected */}
                  <rect 
                    width="80" 
                    height="80" 
                    rx="16" 
                    fill="rgba(0,0,0,0.6)" 
                    stroke={isSelected ? '#cda615' : node.color} 
                    strokeWidth={isSelected ? '3' : '1.5'} 
                    filter={isSelected ? 'url(#glow)' : ''}
                    className="transition-all duration-300"
                  />
                  {/* Icon Placement */}
                  <g transform="translate(24, 15)">
                    <Icon size={32} color={node.color} />
                  </g>
                  {/* Label */}
                  <text 
                    x="40" 
                    y="70" 
                    fill="#ffffff" 
                    fontSize="9" 
                    fontWeight="bold" 
                    textAnchor="middle"
                    fontFamily="monospace"
                  >
                    {node.name.split(' ')[0]}
                  </text>
                </g>
              );
            })}
          </svg>
        </div>

        {/* Component Inspection Details Drawer */}
        <div className="bg-[#0b1310] border border-luxuryGreen-900 rounded-xl p-5 flex flex-col justify-between">
          {selectedNode ? (
            <div className="flex flex-col h-full justify-between">
              <div>
                <div className="flex items-center gap-3 mb-4">
                  <div className="p-3 rounded-lg bg-gray-900/60 border border-luxuryGreen-950" style={{ color: selectedNode.color }}>
                    <selectedNode.icon size={28} />
                  </div>
                  <div>
                    <h3 className="text-lg font-bold text-white">{selectedNode.name}</h3>
                    <span className="text-[10px] uppercase font-mono tracking-wider" style={{ color: selectedNode.color }}>
                      AWS COMPONENT ACTIVE
                    </span>
                  </div>
                </div>

                <p className="text-sm text-gray-300 mb-6 leading-relaxed bg-[#060a08] border border-luxuryGreen-950 p-3 rounded-lg font-sans">
                  {selectedNode.description}
                </p>

                <h4 className="text-xs uppercase font-semibold text-luxuryGold-500 tracking-wider mb-3">AWS Configuration Specifications</h4>
                <div className="space-y-2">
                  {Object.entries(selectedNode.details).map(([key, val]) => (
                    <div key={key} className="flex justify-between border-b border-luxuryGreen-950/60 pb-1.5 text-xs">
                      <span className="text-gray-400 font-mono">{key}</span>
                      <span className="text-white font-medium font-mono">{val}</span>
                    </div>
                  ))}
                </div>
              </div>

              <div className="mt-6 pt-4 border-t border-luxuryGreen-950/60 flex items-center justify-between text-[11px] text-gray-400 font-mono">
                <div className="flex items-center gap-1.5 text-emerald-400">
                  <ShieldCheck size={14} />
                  <span>Config Audited OK</span>
                </div>
                <span>ap-south-1 (Mumbai)</span>
              </div>
            </div>
          ) : (
            <div className="flex flex-col items-center justify-center h-full text-center py-12">
              <Server size={48} className="text-luxuryGreen-800 animate-pulse mb-3" />
              <h3 className="text-base font-bold text-white mb-1">Architecture Inspector</h3>
              <p className="text-xs text-gray-400 max-w-[220px]">Click any architectural block on the canvas to inspect real-time server specifications, security logs, and multi-tier routing configs.</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
