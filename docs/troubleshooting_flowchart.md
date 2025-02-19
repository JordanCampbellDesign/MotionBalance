flowchart TD
    A[Start] --> B{iOS App Launches?}
    B -->|No| C[Check Developer Trust]
    B -->|Yes| D{Permissions Granted?}
    
    C --> C1[Settings > General]
    C1 --> C2[VPN & Device Management]
    C2 --> C3[Trust Developer]
    C3 --> B
    
    D -->|No| E[Grant Permissions]
    D -->|Yes| F{Mac App Launches?}
    
    E --> E1[Settings > Privacy]
    E1 --> E2[Enable Motion]
    E2 --> E3[Enable Bluetooth]
    E3 --> D
    
    F -->|No| G[Check Security]
    F -->|Yes| H{Bluetooth Connected?}
    
    G --> G1[System Settings]
    G1 --> G2[Security & Privacy]
    G2 --> G3[Allow App]
    G3 --> F
    
    H -->|No| I[Bluetooth Troubleshooting]
    H -->|Yes| J[Setup Complete]
    
    I --> I1[Check Bluetooth On]
    I1 --> I2[Verify Range]
    I2 --> I3[Restart Apps]
    I3 --> H 