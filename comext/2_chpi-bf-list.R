library(tidyverse)

tier1 = tribble( 
  ~CN6, ~text,
  "854231" , "Electronic integrated circuits: Processors and controllers, whether or not combined with
memories, converters, logic circuits, amplifiers, clock and timing circuits, or other circuits",
  "854232", "Electronic integrated circuits: Memories",
  "854233", "Electronic integrated circuits: Amplifiers",
  "854239", "Electronic integrated circuits: Other"
) %>%
  mutate(tier = 1)

tier2 = tribble(
  ~CN6, ~text,
  "851762", "Machines for the reception, conversion and transmission or regeneration of voice, images or
  other data, including switching and routing apparatus",
  "852691", "Radio navigational aid apparatus",
  "853221", "Other fixed capacitors: Tantalum capacitors",
  "853224", "Other fixed capacitors: Ceramic dielectric, multilayer",
  "854800", "Electrical parts of machinery or apparatus, not specified or included elsewhere in chapter 85"
)%>%
  mutate(tier = 2)

tier3 = tribble(
  ~CN6, ~text,
  "847150", "Processing units other than those of subheading 8471 41 or 8471 49, whether or not containing
  in the same housing one or two of the following types of unit: storage units, input units, output
  units",
  "850440", "Static converters",
  "851769", "Other apparatus for the transmission or reception of voice, images or other data, including
  apparatus for communication in a wired or wireless network",
  "852589", "Other television cameras, digital cameras and video camera recorders",
  "852910", "Aerials and aerial reflectors of all kinds; parts suitable for use therewith",
  "852990", "Other parts suitable for use solely or principally with the apparatus of headings 8524 to 8528",
  "853669", "Plugs and sockets for a voltage not exceeding 1 000 V",
  "853690", "Electrical apparatus for switching electrical circuits, or for making connections to or in electrical
  circuits, for a voltage not exceeding 1000 V (excluding fuses, automatic circuit breakers and other
                                                apparatus for protecting electrical circuits, relays and other switches, lamp holders, plugs and
                                                sockets)",
  "854110"," Diodes, other than photosensitive or light-emitting diodes (LED)",
  "854121"," Transistors, other than photosensitive transistors with a dissipation rate of less than 1 W",
  "854129"," Other transistors, other than photosensitive transistors",
  "854130"," Thyristors, diacs and triacs (excl. photosensitive semiconductor devices)",
  "854149"," Photosensitive semiconductor devices (excl. Photovoltaic generators and cells)",
  "854151"," Other semiconductor devices: Semiconductor-based transducers",
  "854159"," Other semiconductor devices",
  "854160"," Mounted piezo-electric crystals",
  "848210"," Ball bearings",
  "848220"," Tapered roller bearings, including cone and tapered roller assemblies",
  "848230"," Spherical roller bearings",
  "848250"," Other cylindrical roller bearings, including cage and roller assemblies",
  "880730"," Other parts of aeroplanes, helicopters or unmanned aircraft",
  "901310"," Telescopic sights for fitting to arms; periscopes; telescopes designed to form parts of machines,
  appliances, instruments or apparatus of this chapter or Section XVI",
  "901380"," Other optical devices, appliances and instruments",
  "901420"," Instruments and appliances for aeronautical or space navigation (other than compasses)",
  "901480"," other navigational instruments and appliances",
)%>%
  mutate(tier = 3)

tier4 = tribble(
  ~CN6, ~text,
  "847180", "Units for automatic data-processing machines (excl. processing units, input or output units and
                                                        storage units)",
  "848610", " Machines and apparatus for the manufacture of boules or wafers",
  "848620", " Machines and apparatus for the manufacture of semiconductor devices or of electronic
  integrated circuits",
  "848640", " Machines and apparatus specified in note 11(C) to this chapter",
  "853400", " Printed circuits",
  "854320", " Signal generators",
  "902750", " Other instruments and apparatus using optical radiations (ultraviolet, visible, infrared)",
  "903020", " Oscilloscopes and oscillographs",
  "903032", " Multimeters with recording device",
  "903039", " Instruments and apparatus for measuring or checking voltage, current, resistance or electrical
  power, with recording device",
  "903082", " Instruments and apparatus for measuring or checking semiconductor wafers or devices",
  "845710", " Machining centres for working metal",
  "845811", " Horizontal lathes, including turning centres, for removing metal, numerically controlled",
  "845891", " Lathes (including turning centres) for removing metal, numerically controlled (excluding
                                                                                         horizontal lathes)",
  "845961", "
  Milling machines for metals, numerically controlled (excluding lathes and turning centres of
                                                       heading 8458, way-type unit head machines, drilling machines, boring-milling machines, boring
                                                       machines, and knee-type milling machines)",
  "846693", " Parts and acces"
  
)%>%
  mutate(tier = 4)


chpi = tier1 %>%
  bind_rows(tier2)%>%
  bind_rows(tier3)%>%
  bind_rows(tier4)
