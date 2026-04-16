import sqlite3
import json

db_path = "farmerai_backend/farmer_ai.db"

def populate():
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # --- MACHINERY DATA (10 items) ---
    machinery = [
        ("AgriForce Rentals", "machinery", "John Deere 5105 Tractor", "9876543210", "Strong and efficient 40HP tractor for all seasons.", "₹600/hr", {"hp": "40HP", "year": "2022"}, 17.3850, 78.4867),
        ("Kishan Machine Works", "machinery", "Combine Harvester 950", "9876543211", "High-speed paddy and wheat harvesting.", "₹2500/acre", {"capacity": "High", "brand": "Kartar"}, 17.4000, 78.5000),
        ("Golden Harvest Eq", "machinery", "Rotavator (6 Feet)", "9876543212", "Perfect soil preparation for your crops.", "₹400/hr", {"width": "6ft", "blades": "42"}, 17.4200, 78.4800),
        ("Village Tractor Hub", "machinery", "Mahindra Arjun Nova", "9876543213", "Experience power with the Arjun 605.", "₹850/hr", {"hp": "57HP", "feature": "AC Cabin"}, 17.4500, 78.5200),
        ("Modern Farm Tech", "machinery", "Agricultural Drone Spreading", "9876543214", "Efficient pesticide and fertilizer spraying.", "₹500/acre", {"drone": "DJI Agra T30", "battery": "Backup incl."}, 17.3600, 78.4400),
        ("Pioneer Machinery", "machinery", "Laser Land Leveler", "9876543215", "Precise leveling for better water management.", "₹1200/hr", {"precision": "0.5mm", "control": "GPS"}, 17.4100, 78.5500),
        ("GreenField Rentals", "machinery", "Potato Planter Machine", "9876543216", "Automatic potato sowing with high precision.", "₹1500/day", {"type": "2-row", "capacity": "500kg"}, 17.3900, 78.5800),
        ("Bharat Agri Tools", "machinery", "Mini Power Tiller", "9876543217", "Ideal for small farms and orchards.", "₹300/hr", {"engine": "15HP", "weight": "120kg"}, 17.3500, 78.4000),
        ("Delta Irrigation", "machinery", "Drip Irrigation Pump 5HP", "9876543218", "Powerful solar-powered pump services.", "₹200/hr", {"power": "5HP", "type": "Submersible"}, 17.3200, 78.3800),
        ("Skyline Agro", "machinery", "Straw Reaper & Baler", "9876543219", "Clean your fields and manage fodder.", "₹1000/acre", {"bales": "120/hr", "fuel": "Diesel"}, 17.2800, 78.3500),
    ]

    # --- LABOUR DATA (10 items) ---
    labour = [
        ("Warangal Labour Syndicate", "labour", "Paddy Transplantation Team", "9123456780", "Experienced team of 20 members for quick transplanting.", "₹450/person", {"members": 20, "exp": "10 years"}, 17.9689, 79.5941),
        ("Seva Labour Group", "labour", "Cotton Picking Experts", "9123456781", "Fast and clean cotton picking services.", "₹5/kg", {"members": 15, "season": "Oct-Jan"}, 17.9800, 79.6200),
        ("Rural Force Agents", "labour", "Manual Harvesting Unit", "9123456782", "Hand harvesting for fruits and vegetables.", "₹500/day", {"members": 10, "specialty": "Fruits"}, 17.9500, 79.5500),
        ("Sowing Specialists", "labour", "Seed Sowing Crew", "9123456783", "Expert sowing for maize and pulses.", "₹400/acre", {"members": 8, "tools": "Provided"}, 17.9300, 79.5300),
        ("Unity Workers", "labour", "Weeding & Cleaning Group", "9123456784", "Keep your fields free of weeds.", "₹350/day", {"members": 30, "avail": "Immediate"}, 18.0000, 79.6500),
        ("AgriHelp Squad", "labour", "Pruning & Trimming Team", "9123456785", "Specialized team for mango and citrus orchards.", "₹600/day", {"members": 5, "skill": "Certified"}, 17.9000, 79.5000),
        ("Kishan Shakti", "labour", "Fertilizer Application Crew", "9123456786", "Precise application to maximize yield.", "₹300/acre", {"members": 12, "accuracy": "High"}, 17.8800, 79.4800),
        ("Pragati Labour House", "labour", "Sugarcane Cutting Batch", "9123456787", "Heavy duty cutting and loading service.", "₹450/tonne", {"members": 40, "tools": "Cutters"}, 17.8500, 79.4500),
        ("Village Helpers", "labour", "General Farm Maintenance", "9123456788", "Daily support for all farm tasks.", "₹300/day", {"members": 4, "type": "Family"}, 17.8200, 79.4200),
        ("Star Labour Hub", "labour", "Pesticide Spraying Team", "9123456789", "Equipped with safety gear and sprayers.", "₹400/session", {"members": 6, "gear": "Included"}, 17.8000, 79.4000),
    ]

    # --- FERTILIZERS DATA (10 items) ---
    fertilizers = [
        ("Hyderabad Fertilizer Depot", "fertilizers", "Premium Urea 46%", "9000000000", "High quality nitrogen for green growth.", "₹350/50kg", {"brand": "IFFCO", "stock": "High"}, 17.3850, 78.4867),
        ("Organic Hub India", "fertilizers", "Pure Vermicompost", "9000000001", "Boost soil health naturally.", "₹15/kg", {"type": "Organic", "source": "Earthworm"}, 17.3700, 78.4500),
        ("Bio-Green Solutions", "fertilizers", "Liquid Seaweed Extract", "9000000002", "Concentrated growth promoter.", "₹450/Litre", {"form": "Liquid", "benefit": "Yield increase"}, 17.3500, 78.5000),
        ("Kisan Care Center", "fertilizers", "MOP - Potash fertilizer", "9000000003", "Strengthen your crops against disease.", "₹900/50kg", {"n": "0", "p": "0", "k": "60"}, 17.4000, 78.5000),
        ("Agri Mall", "fertilizers", "Complex NPK (19:19:19)", "9000000004", "All-in-one nutrition for balanced growth.", "₹120/kg", {"solubility": "100%", "method": "Foliar"}, 17.4100, 78.5500),
        ("Green Earth Fertilizers", "fertilizers", "Neem Cake Powder", "9000000005", "Natural fertilizer with pest repelling properties.", "₹60/kg", {"origin": "Neem Seeds", "purity": "100%"}, 17.3600, 78.4400),
        ("Soil Doctor Shop", "fertilizers", "Zinc Sulphate 21%", "9000000006", "Crucial secondary nutrient for growth.", "₹75/kg", {"grade": "Agri", "crystal": "Ensured"}, 17.3900, 78.5800),
        ("Pioneer Agro", "fertilizers", "Sulphur Gold 80%", "9000000007", "Excellent for oilseeds and pulses.", "₹180/kg", {"form": "Pellet", "dispersion": "Quick"}, 17.3500, 78.4000),
        ("Farmer's Trust", "fertilizers", "Specialized Rose Mix", "9000000008", "Best for floriculture and gardens.", "₹250/5kg", {"usage": "Flowers", "results": "Fast"}, 17.3200, 78.3800),
        ("Modern Agri Store", "fertilizers", "Mono Ammonium Phosphate", "9000000009", "Water soluble P-rich fertilizer.", "₹1500/25kg", {"brand": "Coromandal", "stock": "Last few"}, 17.2800, 78.3500),
    ]

    all_data = machinery + labour + fertilizers

    for name, type, title, contact, desc, price, extra, lat, lng in all_data:
        # Create User (contractor) if not exists
        cursor.execute("INSERT OR IGNORE INTO users (name, role, password, phone, specialty, language, rating) VALUES (?, ?, ?, ?, ?, ?, ?)",
                       (name, "contractor", "password123", contact, type.capitalize(), "en", 4.5))
        
        # Create Listing
        # SQLAlchemy stores JSON columns as strings in SQLite, so we need to dump it
        title_json = json.dumps({"en": title})
        desc_json = json.dumps({"en": desc})
        extra_json = json.dumps(extra)
        
        cursor.execute("INSERT INTO listings (contractor_name, type, title, contact, description, price, extra_fields, lat, lng) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                       (name, type, title_json, contact, desc_json, price, extra_json, lat, lng))

    conn.commit()
    conn.close()
    print(f"Successfully added {len(all_data)} listings to the database.")

if __name__ == "__main__":
    populate()
