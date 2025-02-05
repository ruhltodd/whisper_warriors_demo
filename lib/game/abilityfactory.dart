import 'abilities.dart';

class AbilityFactory {
  static Ability? createAbility(String abilityName) {
    switch (abilityName) {
      case 'Whispering Flames':
        print("🔥 Creating Whispering Flames"); // 🔍 Debugging
        return WhisperingFlames();
      case 'Soul Fracture':
        return SoulFracture();
      case 'Shadow Blades':
        return ShadowBlades();
      default:
        print("❌ ERROR: Unknown ability '$abilityName'"); // 🔍 Debugging
    }
  }
}
  /*  case 'Soul Fracture':
        return SoulFracture();
        return null;
    }
  }
}


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