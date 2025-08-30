#!/usr/bin/env bash

 #############################################################################
 #                          GT:NH Server Setup Script                        #
 #                                                                           #
 #    Automated installation and configuration of Greg Tech: New Horizons!   #
 #     Minecraft server with custom world generation and utility settings    #
 #############################################################################


# ┌─────────────────────────────────────────────────────────────────────────┐
# │                            Server Configuration                         │
# └─────────────────────────────────────────────────────────────────────────┘

BASE_DIR="Servers"                    # Root directory for server installations
SERVER_DIR="GTNH"                     # Specific server instance directory
GTNH_VERSION="2.8.0-beta-2"           # Target GT:NH serverpack version
JAVA_VERSION="17-21"                  # Compatible Java version range
USE_BETA="true"                       # Enable beta release channel

# World generation mod versions
RTG_VERSION="1.1.4-GTNH"              # Realistic Terrain Generation
CLIMATE_VERSION="0.10.0-GTNH"         # Climate Control


# ┌─────────────────────────────────────────────────────────────────────────┐
# │                              Color Definitions                          │
# └─────────────────────────────────────────────────────────────────────────┘

# ANSI Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Colored output functions
print_header() { echo -e "${BOLD}${CYAN}$1${NC}"; }
print_success() { echo -e "${GREEN}$1${NC}"; }
print_info() { echo -e "${BLUE}$1${NC}"; }
print_warning() { echo -e "${YELLOW}$1${NC}"; }
print_error() { echo -e "${RED}$1${NC}"; }
print_step() { echo -e "${MAGENTA}$1${NC}"; }

# Progress spinner
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'

    tput civis

    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [${CYAN}%c${NC}]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"

    tput cnorm
}

# Download with custom progress
download_with_progress() {
    local url="$1"
    local output="$2"
    local desc="$3"

    echo -ne "   ${BLUE}•${NC} $desc"

    if [ -n "$output" ]; then
        wget --quiet -O "$output" "$url" &
    else
        wget --quiet "$url" &
    fi

    show_spinner $!
    wait $!
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo -e " ${GREEN}✓${NC}"
    else
        echo -e " ${RED}✗${NC}"
        return $exit_code
    fi
    sleep 0.3
}

# Extract with custom progress
extract_with_progress() {
    local archive="$1"
    local desc="$2"

    echo -ne "   ${YELLOW}•${NC} $desc"

    unzip -q "$archive" &
    show_spinner $!
    wait $!
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo -e " ${GREEN}✓${NC}"
    else
        echo -e " ${RED}✗${NC}"
        return $exit_code
    fi
    sleep 0.1
}

# Run with custom progress
run_with_progress() {
    local color="$1"
    local desc="$2"
    shift 2

    echo -ne "   ${color}•${NC} $desc"

    "$@" &
    show_spinner $!
    wait $!
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo -e " ${GREEN}✓${NC}"
    else
        echo -e " ${RED}✗${NC}"
        return $exit_code
    fi

    sleep 0.1
}



# ┌─────────────────────────────────────────────────────────────────────────┐
# │                         Dependency Verification                         │
# └─────────────────────────────────────────────────────────────────────────┘

clear

REQUIRED_TOOLS=("wget" "unzip" "sed" "rsync")
MISSING_TOOLS=()

print_info "🔍 Checking system dependencies..."
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        MISSING_TOOLS+=("$tool")
    fi
done

sleep 0.3

if [ "${#MISSING_TOOLS[@]}" -ne 0 ]; then
    print_error "❌ Error: Missing required tools:"
    for tool in "${MISSING_TOOLS[@]}"; do
        echo -e "   ${RED}•${NC} $tool"
    done
    echo ""
    print_warning "Please install missing tools and retry."
    exit 1
fi
print_success "✅ All dependencies satisfied"

sleep 0.3


# ┌─────────────────────────────────────────────────────────────────────────┐
# │                              URL Construction                           │
# └─────────────────────────────────────────────────────────────────────────┘

SERVER_ZIP="GT_New_Horizons_${GTNH_VERSION}_Server_Java_${JAVA_VERSION}.zip"
BASE_DOWNLOAD_URL="https://downloads.gtnewhorizons.com/ServerPacks"

STABLE_URL="${BASE_DOWNLOAD_URL}/${SERVER_ZIP}"
BETA_URL="${BASE_DOWNLOAD_URL}/betas/${SERVER_ZIP}"

if [ "$USE_BETA" = "true" ]; then
    SERVER_URL="$BETA_URL"
    print_warning "🧪 Using beta release channel"
else
    SERVER_URL="$STABLE_URL"
    print_info "🔒 Using stable release channel"
fi

# Mod download URLs
RTG_BASE_URL="https://github.com/GTNewHorizons/Realistic-Terrain-Generation/releases/download"
CLIMATE_BASE_URL="https://github.com/GTNewHorizons/Climate-Control/releases/download"

RTG_URL="${RTG_BASE_URL}/${RTG_VERSION}/RTG-${RTG_VERSION}.jar"
CLIMATE_URL="${CLIMATE_BASE_URL}/${CLIMATE_VERSION}/ClimateControl-${CLIMATE_VERSION}.jar"

# Configuration repository
MAKER_BRANCH="main"
MAKER_ZIP="${MAKER_BRANCH}.zip"
MAKER_URL="https://github.com/Undercoverer/gtnh-maker/archive/refs/heads/${MAKER_ZIP}"


# ┌─────────────────────────────────────────────────────────────────────────┐
# │                          Installation Process                           │
# └─────────────────────────────────────────────────────────────────────────┘

echo ""
print_header "🚀 Beginning GT:NH server setup..."
echo -e "   ${GRAY}Target: ${WHITE}${PWD}/${BASE_DIR}/${SERVER_DIR}${NC}"
echo -e "   ${GRAY}Version: ${WHITE}${GTNH_VERSION}${NC}"
echo ""

sleep 2


# ┌─────────────────────────────────────────────────────────────────────────┐
# │                            Directory Setup                              │
# └─────────────────────────────────────────────────────────────────────────┘

print_step "📁 Preparing directory structure..."
run_with_progress "${MAGENTA}" "Creating and entering server directory..." mkdir -p "${BASE_DIR}/${SERVER_DIR}"
cd "${BASE_DIR}/${SERVER_DIR}"
echo ""


# ┌─────────────────────────────────────────────────────────────────────────┐
# │                          Server Pack Download                           │
# └─────────────────────────────────────────────────────────────────────────┘

print_step "⬇️ Downloading server pack..."
echo -e "   ${CYAN}•${NC} ${GRAY}Source: ${WHITE}$(basename "$SERVER_URL")${NC}"
download_with_progress "${SERVER_URL}" "" "Fetching GT:NH server archive..."
echo ""
print_step "📦 Extracting server pack..."
extract_with_progress "./${SERVER_ZIP}" "Unpacking server files..."
run_with_progress "${RED}" "Cleaning up server pack file..." rm "./${SERVER_ZIP}"
echo ""

sleep 2


# ┌─────────────────────────────────────────────────────────────────────────┐
# │                      Server Utilities Configuration                     │
# └─────────────────────────────────────────────────────────────────────────┘

print_step "⚙️ Configuring server utilities..."
run_with_progress "${CYAN}" "Set explosion perms by team..." sed -i 's/S:enable_explosions=TRUE/S:enable_explosions=DEFAULT/' serverutilities/serverutilities.cfg
run_with_progress "${CYAN}" "Only backup claimed chunks..." sed -i 's/B:only_backup_claimed_chunks=false/B:only_backup_claimed_chunks=true/' serverutilities/serverutilities.cfg
run_with_progress "${CYAN}" "Enable /back..." sed -i 's/B:back=false/B:back=true/' serverutilities/serverutilities.cfg
run_with_progress "${CYAN}" "Enable /home..." sed -i 's/B:home=false/B:home=true/' serverutilities/serverutilities.cfg
run_with_progress "${CYAN}" "Enable /rtp..." sed -i 's/B:rtp=false/B:rtp=true/' serverutilities/serverutilities.cfg
run_with_progress "${CYAN}" "Enable /tpa..." sed -i 's/B:tpa=false/B:tpa=true/' serverutilities/serverutilities.cfg
run_with_progress "${CYAN}" "Enable chunk claiming..." sed -i 's/B:chunk_claiming=false/B:chunk_claiming=true/' serverutilities/serverutilities.cfg
run_with_progress "${CYAN}" "Disable player suffocation damage..." sed -i 's/B:disable_player_suffocation_damage=false/B:disable_player_suffocation_damage=true/' serverutilities/serverutilities.cfg
run_with_progress "${CYAN}" "Enable rank control of permissions..." sed -i '/^ranks {/,/^}/ s/^\(\s*B:enabled\s*=\s*\)false/\1true/' serverutilities/serverutilities.cfg
echo ""

sleep 2


# ┌─────────────────────────────────────────────────────────────────────────┐
# │                               World Gen                                 │
# └─────────────────────────────────────────────────────────────────────────┘

print_step "🌍 Updating world generation mods..."
run_with_progress "${RED}" "Removing RWG (Realistic World Gen)..." rm mods/RWG*
download_with_progress "${RTG_URL}" "mods/$(basename "${RTG_URL}")" "Installing RTG (Realistic Terrain Generation)..."
download_with_progress "${CLIMATE_URL}" "mods/$(basename "${CLIMATE_URL}")" "Installing Climate Control..."
echo ""

sleep 2


# ┌─────────────────────────────────────────────────────────────────────────┐
# │                         World Gen Configuration                         │
# └─────────────────────────────────────────────────────────────────────────┘

print_step "🗺️ Configuring world generation settings..."
run_with_progress "${CYAN}" "Setting default world generator to RTG..." sed -i 's/S:"World Generator"=RWG/S:"World Generator"=RTG/' config/defaultworldgenerator.cfg
run_with_progress "${CYAN}" "Updating server.properties..." sed -i \
  -e 's/level-type=rwg/level-type=rtg/' \
  -e 's/spawn-protection=1/spawn-protection=0/' \
  server.properties
echo ""

sleep 2


# ┌─────────────────────────────────────────────────────────────────────────┐
# │                        Custom Configuration Overlay                     │
# └─────────────────────────────────────────────────────────────────────────┘

print_step "📋 Applying custom configuration files..."
sleep 0.3
download_with_progress "${MAKER_URL}" "" "Downloading configuration repository..."
extract_with_progress "${MAKER_ZIP}" "Extracting configuration files..."
run_with_progress "${MAGENTA}" "Synchronizing config files..." rsync -a "gtnh-maker-${MAKER_BRANCH}/config/" "config/"
run_with_progress "${MAGENTA}" "Synchronizing server utilities..." rsync -a "gtnh-maker-${MAKER_BRANCH}/serverutilities/" "serverutilities/"
run_with_progress "${GRAY}" "Cleaning up temporary files..." bash -c 'rm -r "gtnh-maker-$1/" && rm "$2"' _ "$MAKER_BRANCH" "$MAKER_ZIP"
echo ""

sleep 2


# ┌─────────────────────────────────────────────────────────────────────────┐
# │                              Final Fixes                                │
# └─────────────────────────────────────────────────────────────────────────┘

print_step "🛠️ Applying final fixes..."
run_with_progress "${CYAN}" "Making server executable..." chmod +x startserver-java9.sh
run_with_progress "${CYAN}" "Accepting EULA..." sed -i 's/false/true/g' eula.txt
echo ""

sleep 0.5

# ═══════════════════════════════════════════════════════════════════════════
#                            Installation Complete
# ═══════════════════════════════════════════════════════════════════════════

echo ""
print_success "✨ GT:NH server setup completed successfully!"
echo ""
echo -e "${BOLD}📍 Server location:${NC} ${WHITE}${PWD}/${BASE_DIR}/${SERVER_DIR}${NC}"
echo -e "${BOLD}🎮 To start the server, run:${NC} ${GREEN}./${BASE_DIR}/${SERVER_DIR}/startserver-java9.sh${NC}"
echo ""

