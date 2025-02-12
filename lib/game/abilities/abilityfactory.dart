import 'abilities.dart';

class AbilityFactory {
  static final List<String> abilityUnlockOrder = [
    'Whispering Flames',
    'Soul Fracture',
    'Shadow Blades',
    'Cursed Echo',
    'Fading Crescent',
    'Vampiric Touch',
    'Unholy Fortitude',
    'Will of the Forgotten',
    'Spectral Chain',
    'Chrono Echo',
    'Time Dilation',
    'Revenants Stride',
  ];
  static Ability? createAbility(String abilityName) {
    switch (abilityName) {
      case 'Whispering Flames':
        return WhisperingFlames();
      case 'Soul Fracture':
        return SoulFracture();
      case 'Shadow Blades':
        return ShadowBladesAbility();
      case 'Cursed Echo':
        return CursedEcho();
      default:
        print("❌ ERROR: Unknown ability '$abilityName'"); // 🔍 Debugging
    }
    return null;
  }
}

/*
   case 'Soul Fracture':
        return SoulFracture();
      case 'Fading Crescent':
        return FadingCrescent();
      case 'Vampiric Touch':
        return VampiricTouch();
      case 'Unholy Fortitude':
        return UnholyFortitude();
      case 'Will of the Forgotten':
        return WillOfTheForgotten();
      /* case 'Spectral Chain':
        return SpectralChain();
      case 'Chrono Echo':
        return ChronoEcho();
      case 'Time Dilation':
        return TimeDilation();
      case 'Revenants Stride':
        return RevenantsStride();*/
      default:
        return null;
    } */
