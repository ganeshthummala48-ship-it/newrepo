class TelanganaLocations {
  static const List<String> districts = [
    "Adilabad",
    "Bhadradri Kothagudem",
    "Hanumakonda",
    "Hyderabad",
    "Jagtial",
    "Jangaon",
    "Jayashankar Bhupalpally",
    "Jogulamba Gadwal",
    "Kamareddy",
    "Karimnagar",
    "Khammam",
    "Kumuram Bheem Asifabad",
    "Mahabubabad",
    "Mahabubnagar",
    "Mancherial",
    "Medak",
    "Medchal-Malkajgiri",
    "Mulugu",
    "Nagarkurnool",
    "Nalgonda",
    "Narayanpet",
    "Nirmal",
    "Nizamabad",
    "Peddapalli",
    "Rajanna Sircilla",
    "Ranga Reddy",
    "Sangareddy",
    "Siddipet",
    "Suryapet",
    "Vikarabad",
    "Wanaparthy",
    "Warangal",
    "Yadadri Bhuvanagiri",
  ];

  static const Map<String, List<String>> mandalsMap = {
    "Adilabad": ["Adilabad Urban", "Adilabad Rural", "Jainad", "Bela", "Utnoor", "Indervelly", "Narnoor", "Ichoda", "Bazarhathnoor", "Gudihathnoor", "Boath", "Mavala", "Sirikonda"],
    "Bhadradri Kothagudem": ["Kothagudem", "Palwancha", "Bhadrachalam", "Manuguru", "Yellandu", "Aswapuram", "Burgampahad", "Chandrugonda", "Cherla", "Dummagudem", "Karakagudem", "Mulakalapalle"],
    "Hanumakonda": ["Hanamkonda", "Kazipet", "Kamalapur", "Bheemadevarapalle", "Elkathurthy", "Inavolu", "Velair", "Parkal", "Atmakur"],
    "Hyderabad": ["Amberpet", "Asifnagar", "Bahadurpura", "Bandlaguda", "Charminar", "Golconda", "Himayatnagar", "Khairatabad", "Marredpally", "Musheerabad", "Nampally", "Saidabad", "Secunderabad", "Shaikpet"],
    "Jagtial": ["Jagtial Urban", "Jagtial Rural", "Korutla", "Metpally", "Raikal", "Sarangapur", "Dharmapuri", "Buggaram", "Birpur", "Mallial", "Kodimial", "Pegadapally"],
    "Jangaon": ["Jangaon", "Bachannapet", "Devaruppula", "Ghanpur Station", "Lingalaghanpur", "Narmetta", "Raghunathpally", "Tarigoppula", "Zaffergadh"],
    "Jayashankar Bhupalpally": ["Bhupalpally", "Chityal", "Ghanpur", "Kataram", "Mahadevpur", "Maha Mutharam", "Malhar Rao", "Mogullapally", "Palimela", "Regonda", "Tekumatla"],
    "Jogulamba Gadwal": ["Gadwal", "Dharoor", "Ghattu", "Ieeja", "Itikyal", "Kothakota", "Maldakal", "Manopad", "Rajoli", "Undavelly", "Waddepalle"],
    "Kamareddy": ["Kamareddy", "Banswada", "Bhiknoor", "Bibipet", "Domakonda", "Jukkal", "Lingampet", "Machareddy", "Madnoor", "Nasirabad", "Pitlam", "Rajampet", "Sadashivanagar", "Yellareddy"],
    "Karimnagar": ["Karimnagar Urban", "Karimnagar Rural", "Choppadandi", "Ganneruvaram", "Gangadhara", "Huzurabad", "Jammikunta", "Kothapally", "Manakondur", "Ramadugu", "Shankarapatnam", "Thimmapur", "Veenavanka"],
    "Khammam": ["Khammam Urban", "Khammam Rural", "Bonakal", "Chinthakani", "Enkkoor", "Kalluru", "Kamepalli", "Konijerla", "Kusumanchi", "Madhira", "Mudigonda", "Nelakondapalli", "Penuballi", "Raghunathapalem", "Sathupally", "Singareni", "Thallada", "Tirumalayapalem", "Wyra"],
    "Kumuram Bheem Asifabad": ["Asifabad", "Sirpur-T", "Kaghaznagar", "Rebbena", "Tandur", "Kerameri", "Jainoor", "Narnoor", "Tiryani"],
    "Mahabubabad": ["Mahabubabad", "Bayyaram", "Chinnagudur", "Danthalapalle", "Dornakal", "Garla", "Gudur", "Kesamudram", "Kothaguda", "Kuravi", "Maripeda", "Nellikudur", "Narsimhulapet", "Thorrur"],
    "Mahabubnagar": ["Mahabubnagar Urban", "Mahabubnagar Rural", "Addakal", "Balanagar", "Bhutpur", "Devarkadra", "Gandeed", "Hanwada", "Jadcherla", "Koilkonda", "Midjil", "Nawabpet", "Rajapur"],
    "Mancherial": ["Mancherial", "Bellampalle", "Chennur", "Dandepalle", "Jannaram", "Jaipur", "Kotapalle", "Luxettipet", "Mandamarri", "Naspur", "Vemanpalle"],
    "Medak": ["Medak Urban", "Medak Rural", "Alladurg", "Chegunta", "Havelighanpur", "Kowdipally", "Manorabad", "Narsapur", "Papannapet", "Ramayampet", "Regode", "Shankarampet-A", "Shankarampet-R", "Shivampet", "Tekmal", "Toopran", "Yeldurthy"],
    "Medchal-Malkajgiri": ["Alwal", "Balanagar", "Gandimaisamma", "Ghatkesar", "Kapra", "Kukatpally", "Malkajgiri", "Medchal", "Muduchintalapalli", "Quthbullapur", "Shamirpet", "Uppal"],
    "Mulugu": ["Mulugu", "Govindaraopet", "Eturnagaram", "Mangapet", "Tadvai", "Wazeedu", "Venkatapur", "Kannaiyagudem"],
    "Nagarkurnool": ["Nagarkurnool", "Bijinapally", "Charakonda", "Kalwakurthy", "Kodair", "Kollapur", "Lingal", "Telkapally", "Thimmajipet", "Urkonda", "Veldanda"],
    "Nalgonda": ["Miryalaguda", "Nalgonda Urban", "Nalgonda Rural", "Chandur", "Chityal", "Devarakonda", "Gundlapally", "Haliya", "Huzurnagar", "Kanagal", "Kattangoor", "Madugulapally", "Marriguda", "Munugode", "Nakrekal", "Narketpally", "Nidamanoor", "Peddavoora", "Shaligouraram", "Thipparthy", "Tirumalagiri"],
    "Narayanpet": ["Narayanpet", "Damaragidda", "Dhanwada", "Maddur", "Maganoor", "Makthal", "Markal", "Narwa", "Utkoor"],
    "Nirmal": ["Nirmal Urban", "Nirmal Rural", "Bhainsa", "Basar", "Dilawarpur", "Kaddam", "Khanapur", "Kubeer", "Laxmanchanda", "Lokeshwaram", "Mamda", "Mudhole", "Narsapur-G", "Pembi", "Soan"],
    "Nizamabad": ["Nizamabad Urban", "Nizamabad Rural", "Armoor", "Balkonda", "Bodhan", "Bheemgal", "Dichpally", "Dharpally", "Indalwai", "Jakranpally", "Makloor", "Morthad", "Nandipet", "Navipet", "Renjal", "Rudrur", "Sirikonda", "Varni", "Velpur"],
    "Peddapalli": ["Peddapalli", "Anthergoam", "Dharmaram", "Eligaid", "Julapalle", "Kamanpur", "Manthani", "Mutharam", "Odela", "Palakurthi", "Ramagundam", "Sulthanabad"],
    "Rajanna Sircilla": ["Sircilla", "Chandurthi", "Ellanthakunta", "Gambhiraopet", "Konaraopet", "Mustabad", "Rudrangi", "Thangallapally", "Veernapally", "Yellareddypet"],
    "Ranga Reddy": ["Abdullapurmet", "Amangal", "Chevella", "Farooqnagar", "Hayathnagar", "Ibrahimpatnam", "Kandukur", "Keshampet", "Kondurg", "Kothur", "Maheshwaram", "Manchal", "Moinabad", "Nandigama", "Shamshabad", "Shabad", "Shankarpalle", "Yacharam"],
    "Sangareddy": ["Sangareddy", "Ameenpur", "Gummadidala", "Jinnaram", "Kandi", "Kohir", "Kondapur", "Munipally", "Narayankhed", "Nyalkal", "Patancheru", "Pulkal", "Sadasivpet", "Sirgapoor", "Vatpally", "Zaheerabad"],
    "Siddipet": ["Siddipet Urban", "Siddipet Rural", "Bejjanki", "Cherial", "Chinnakodur", "Dhoolmitta", "Dubbak", "Gajwel", "Husnabad", "Jagdevpur", "Komuravelli", "Kondapak", "Markook", "Mirdoddi", "Mulugu", "Narayanraopet", "Nangnoor", "Raipole", "Thoguta", "Wargal"],
    "Suryapet": ["Suryapet", "Ananthagiri", "Atmakur-S", "Chivemla", "Garidepally", "Huzurnagar", "Kodad", "Mellachervu", "Munagala", "Nadigudem", "Nereducherla", "Noothankal", "Penpahad", "Tirumalagiri", "Tripuraram"],
    "Vikarabad": ["Vikarabad", "Basheerabad", "Bomraspet", "Doma", "Dharur", "Doulthabad", "Kulkacharla", "Kotepally", "Marpalle", "Mominpet", "Nawabpet", "Pargi", "Pudur", "Tandur", "Yelal"],
    "Wanaparthy": ["Wanaparthy", "Atmakur", "Amarachinta", "Gopalpet", "Kothakota", "Madanapur", "Pangal", "Pebbair", "Revally", "Srirangapur", "Veepangandla"],
    "Warangal": ["Warangal Urban", "Chennaraopet", "Duggondi", "Geesugonda", "Khanapur", "Narsampet", "Nekkonda", "Parvathagiri", "Raiparthy", "Sangem", "Wardhannapet"],
    "Yadadri Bhuvanagiri": ["Bhongir", "Alair", "Atmakur-M", "Bibi Nagar", "Bommalaramaram", "Choutuppal", "Motakondur", "Mothkur", "Pochampally", "Rajapet", "Turkapally", "Valigonda", "Yadagirigutta"],
  };

  static List<String> getMandals(String district) {
    return mandalsMap[district] ?? ["Central Mandal", "North Mandal", "South Mandal", "East Mandal", "West Mandal"];
  }

  static List<String> getVillages(String district, String mandal) {
    return [
      "$mandal Main Market",
      "$mandal PACS Center",
      "$mandal Rythu Seva Hub",
      "$mandal North Village",
      "$mandal South Gramam",
      "$mandal Agricultural Depot"
    ];
  }
}
