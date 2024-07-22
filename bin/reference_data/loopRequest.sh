#!/bin/bash

# Partie A : initialisation des variables

# Options
vVerbose=0
vQuite=0
vHelp=0
vStep=1
vOffset=0
vRetry=0
vTempo=1000
vRecurCallLvl=0
vRecursLimit=11 # 7 DICHOTOMY (pour 100) + 4 BACKUP / RETRY
vOut=""
vURL=""
vURLBU=""
vLabel=""
vFormat="json"
vExtraHeader=""
vIdxPad=0

# Fonction pour afficher l'aide
display_help() {
		echo "Usage: $0 [-v] [-q] [-h] [-S <STEP>] [-I <IGNORE>] [-R <RETRY>] [-T <TEMPO>] [-O <DIR>] [-U <URL>] [-L <LABEL>] [-F <EXTENSION>] [-H <HEADER>]" >&2
		echo
		echo "Options:"
		echo "  -v              Activer le mode verbose (0 ou 1, défaut = 0)"
		echo "  -q              Activer le mode quiet (0 ou 1, défaut = 0)"
		echo "  -h              Afficher l'aide"
		echo "  -S <STEP>       Définir la taille du pas entre chaque recall(1 à 100, défaut = 1)"
		echo "  -I <IGNORE>     Nombre de résultat à ignorer lors de la première requête (1 à 100, défaut = 1)"
		echo "  -R <RETRY>      Définir le nombre de recall (0 à 1 000 000, défaut = 0)"
		echo "  -T <TEMPO>      Définir la temporisation en millisecondes (0 à 3 600 000, défaut = 1000)"
		echo "  -O <DIR>        Définir le répertoire de sortie (writable directory path)"
		echo "  -U <URL>        Définir l'URL de l'API"
		echo "  -B <URL_BACKUP> Définir l'URL de l'API à utiliser en dernier recours dans le procéssus de reprise sur erreur"
		echo "  -L <LABEL>      Définir l'étiquette de l'endpoint"
		echo "  -F <EXTENSION>  Définir l'extension du fichier (défaut = \"json\")"
		echo "  -H <HEADER>     Définir l'en-tête supplémentaire à ajouter"
		echo "  -C <RCALLCNT>   Compteur d'appels récursifs utilisé pour la récupération automatique des erreurs limité à ${vRecursLimit} (défaut = 0)"
		echo "  -P <IDXPAD>     Nombre de digits pour faire le padding 0 sur les index (défaut : calculé automatiquement)"
		exit 0
}

# Récupération des options
while getopts ":vqhS:I:R:T:O:U:B:L:F:H:C:P:" opt; do
	case $opt in
		v) vVerbose=1 ;;
		q) vQuite=1 ;;
		h) vHelp=1 ;;
		S) vStep=$OPTARG ;;
		I) vOffset=$OPTARG ;;
		R) vRetry=$OPTARG ;;
		T) vTempo=$OPTARG ;;
		O) vOut=$OPTARG ;;
		U) vURL=$OPTARG ;;
		B) vURLBU=$OPTARG ;;
		L) vLabel=$OPTARG ;;
		F) vFormat=$OPTARG ;;
		H) vExtraHeader=$OPTARG ;;
		C) vRecurCallLvl=$OPTARG ;;
		P) vIdxPad=$OPTARG ;;
		\?) echo "Option invalide: -$OPTARG" >&2; exit 1 ;;
	esac
done

# Affichage de l'aide et sortie si vHelp est activé
if [ $vHelp -eq 1 ]; then
	display_help
fi

if [ $vQuite -eq 1 ]; then
	vVerbose=0
fi

# On passe un nombre d'enregistrement a ignorer (l'offset vaut 1 de plus)
# l'API retourne le meme resultat pour les offset 0 et 1, il vaut mieux commencer par 1
vOffset=$((vOffset + 1))

# Fonction d'affichage des erreurs sur la sortie standard ou d'erreurs
print_error() {
	local message="$1"
	if [ $vQuite -eq 1 ]; then
		echo "$message" >&2
	else
		echo "$message"
	fi
}

# Function: isNumeric
# Description: Checks if a given value is numeric.
# Parameters:
#   - pNum: The value to check for numericity.
# Returns:
#   - 1 if the value is numeric, 0 otherwise.
#
# Example:
#   result=$(isNumeric "42")
#   echo "Is 42 numeric? Result: $result" # Output: "Is 42 numeric? Result: 1"
isNumeric() {
	local pNum=${1:-""}
	local vIsNumeric=0

	# Check if pNum is not empty and is equal to itself (a numeric check), redirecting error output to null.
	if [ -n "$pNum" ] && [ "$pNum" -eq "$pNum" ] 2>/dev/null; then
		vIsNumeric=1
	fi
	
	echo "${vIsNumeric}"
}

# Return a strings which represents a delay.
#
# @param pMsec delay to convert un millisecondes
# @return 
#		 Examples :
#		 - displayDelayMs 86464321 => 1D 00:01:04.321
#		 - displayDelayMs 3604321 => 01:00:04.321
#		 - displayDelayMs -3540000 => 00:59:00.000
#		 - displayDelayMs foo => invalid (foo)
function displayDelayMs {
	local pMsec=$1
	local vRet=""
	  
	if [ $(isNumeric $pMsec) -ne 1  ] 2>/dev/null; then
		vRet="invalid (${pMsec})"
	else
		if [[ "${pMsec:0:1}" == "-" ]]; then
			pMsec="${pMsec#-}"
		fi
		local vSecs=$((pMsec/1000))
		local vMins=$((vSecs/60))
		local vHours=$((vMins/60))
		local vDays=$((vHours/24))

		local vRmsec=$((pMsec%1000))
		local vRsecs=$((vSecs%60))
		local vRmins=$((vMins%60))
		local vRhours=$((vHours%24))
		if [ $vDays -gt 0  ] 2>/dev/null; then
			vRet=$(printf '%dD ' "$vDays" )
		fi
		vRet=$(printf '%s%02d:%02d:%02d.%03d' "$vRet" "$vRhours" "$vRmins" "$vRsecs" "$vRmsec" )
	fi
	
	echo "$vRet"
}

# Fonction de validation des variables numériques
validateNumericVariable() {
	local pVarLabel="$1"
	local pVarValue="$2"
	local pMinValue="$3"
	local pMaxValue="$4"
	local vValidateNumericVariable=""
	
	if ! [[ "$pVarValue" =~ ^[0-9]+$ ]]; then
		print_error "$pVarLabel doit être numérique."
		exit -1
	fi
	vValidateNumericVariable=$pVarValue
	if [ $(isNumeric $pMinValue) -eq 1 ] 2>/dev/null && [ "$pVarValue" -lt "$pMinValue" ]; then
		vValidateNumericVariable=$pMinValue
	fi
	
	if [ $(isNumeric $pMaxValue) -eq 1 ] 2>/dev/null && [ "$pVarValue" -gt "$pMaxValue" ]; then
		vValidateNumericVariable=$pMaxValue
	fi
	
	echo "$vValidateNumericVariable"
}

# Validation des variables numériques
vStep=$(validateNumericVariable "STEP" "$vStep" 1 100)
vRetry=$(validateNumericVariable "RETRY" "$vRetry" 0 1000000)
vOffset=$(validateNumericVariable "IGNORE" "$vOffset" 0 1000000)
vTempo=$(validateNumericVariable "TEMPO" "$vTempo" 0 3600000)
vRecurCallLvl=$(validateNumericVariable "RCALLCNT" "$vRecurCallLvl" 0)

vTotalRequest=$((vRetry + 1 ))
vAbsStartOffset=$vOffset
vAbsEndOffset=$(( vAbsStartOffset - 1 + vStep * vTotalRequest ))
if [ -z "$vIdxPad" ] || [[ $vIdxPad -lt 1 ]]; then
	vIdxPad=${#vAbsEndOffset}
fi
vIdxPad=$(validateNumericVariable "IDXPAD" "$vIdxPad" 0)

vTempoSecondes=$(echo "scale=3; $vTempo / 1000" | bc)

# Validation des autres variables
if [ -z "$vOut" ]; then
	print_error "DIR ne doit pas être vide."
	exit -5
elif [ ! -d "$vOut" ]; then
	print_error "DIR doit être un dossier valide."
	exit -6
elif [ ! -w "$vOut" ]; then
	print_error "Le répertoire de sortie n'est pas accessible en écriture."
	exit -7
elif [ -z "$vURL" ]; then
	print_error "URL ne doit pas être vide."
	exit -8
elif [[ ! "$vURL" =~ ^https?:// ]]; then
	print_error "URL doit commencer par 'http://' ou 'https://'."
	exit -9
elif [[ -n "$vURLBU" ]] && [[ ! "$vURLBU" =~ ^https?:// ]]; then
	print_error "URL_BACKUP doit commencer par 'http://' ou 'https://'."
	exit -10
elif [[ ! "$vLabel" =~ ^[[:alnum:]_\.-]+$ ]]; then
	print_error "LABEL ne doit contenir que des caractères alphanumériques, '-', '_', ou '.'."
	exit -11
elif [[ $vRecurCallLvl -gt $vRecursLimit ]]; then
	print_error "Limite maximum d'appels recursifs atteinte : $vRecurCallLvl > $vRecursLimit."
	exit -12
fi



vOptInsecure=""
if [[ $vURL == https://* ]]; then
	vOptInsecure=" -k "
fi

# Initialisation des autres variables
vLastIdxPage=$vTotalRequest
vRetryNbDig=${#vLastIdxPage}
vParamInURL=0
if [[ "$vURL" == *\?* ]]; then
	vParamInURL=1
fi
vCurrentIdxPage=1
vExecutionStartDate=$(date +'%Y%m%d_%H%M%S')
vLblCurrentIdxPage=$(printf "%0${vRetryNbDig}d" $vCurrentIdxPage)
vCurrentStartOffset=$vOffset
vCurrentEndOffset=$((vCurrentStartOffset - 1 + vStep))
vLblCurrentStartOffset=$(printf "%0${vIdxPad}d" $vCurrentStartOffset)
vLblCurrentEndOffset=$(printf "%0${vIdxPad}d" $vCurrentEndOffset)

vCurrentPageOut="${vLabel}_200_${vLblCurrentStartOffset}_to_${vLblCurrentEndOffset}_T${vRecurCallLvl}_p${vLblCurrentIdxPage}_${vLastIdxPage}_${vExecutionStartDate}.${vFormat}"
if [ $vParamInURL -eq 1 ]; then
	vSepLimit="&"
else
	vSepLimit="?"
fi
vCurrentRqst="${vURL}${vSepLimit}limit=${vStep}&offset=${vOffset}"
vExtraHeaderPassthru=""
if [ -n "$vExtraHeader" ]; then
	vExtraHeaderPassthru=" -H \"${vExtraHeader}\" "
fi
vNbRequest=0

# Partie B : résumé

if [ $vQuite -ne 1 ]; then
	echo "Options :"
	echo "	Mode verbose : $(if [ $vVerbose -eq 1 ]; then echo "oui"; else echo "non"; fi)"
	echo "Entree :"
	echo "	Endpoint : $vLabel"
	echo "	URL : $vURL"
	echo "	Pas : $vStep"
	echo "	Premiere requete : $vCurrentRqst"
	echo "	Nombre de requetes : $vTotalRequest"
	echo "	Index de départ: $vAbsStartOffset"
	echo "	Index de fin : $vAbsEndOffset"
	if [[ $vRecurCallLvl -gt 0 ]]; then
		echo "	Niveau de recursivité : ${vRecurCallLvl}"
	fi
	echo "	Temporisation : $(printf "%02d:%02d:%02d" $(($vTempo/3600000)) $(($vTempo%3600000/60000)) $(($vTempo%60000/1000)))"
	echo "	Estimation de la duree totale d'execution : $(printf "%02d:%02d:%02d" $(($vRetry*$vTempo/3600000)) $(($vRetry*$vTempo%3600000/60000)) $(($vRetry*$vTempo%60000/1000)))"
	echo "	Date estimée de fin d'exécution : $(date -d "+$(($vRetry*$vTempo/1000)) seconds" +'%Y-%m-%d %H:%M:%S')"
	echo "Sortie :"
	echo "	Repertoire de sortie : $vOut"
	echo "	Fichier de sauvegarde premiere page : $vCurrentPageOut"
	echo "	Format : $vFormat"
fi

# partie C : Execution

declare -A vArrPerRes
vRetCodeList=""
vSumRetCode=0
vStartTimeMs=$(date +%s%3N)
vStartTime=$(date +'%Y-%m-%d %H:%M:%S')

declare -A vArrRecupAuto
vErrorCounter=0

while [ $vCurrentIdxPage -le $vLastIdxPage ]; do
	vLblTmstmpCur=$(date +'%Y%m%d_%H%M%S')
	vCurrentRqst="${vURL}${vSepLimit}limit=${vStep}&offset=${vOffset}"
	vLblCurrentIdxPage=$(printf "%0${vRetryNbDig}d" $vCurrentIdxPage)
	vCurrentStartOffset=$vOffset
	vCurrentEndOffset=$((vCurrentStartOffset - 1 + vStep))
	vLblCurrentStartOffset=$(printf "%0${vIdxPad}d" $vCurrentStartOffset)
	vLblCurrentEndOffset=$(printf "%0${vIdxPad}d" $vCurrentEndOffset)
	
	if [ $vQuite -ne 1 ]; then
		echo "${vLblCurrentIdxPage} / ${vLastIdxPage} : ${vCurrentRqst}"
	fi
	# Faire la requête
	tmp_file="${vOut}${vLabel}_200_${vLblCurrentStartOffset}_to_${vLblCurrentEndOffset}_T${vRecurCallLvl}_p${vLblCurrentIdxPage}_${vLastIdxPage}_${vLblTmstmpCur}_TMP.${vFormat}"
	
	if [ $vVerbose -eq 1 ]; then
		echo "curl -s -o \"$tmp_file\" -w \"%{http_code}\"${vExtraHeaderPassthru}${vOptInsecure}\"$vCurrentRqst\""
	fi
	if [ -n "$vExtraHeader" ]; then
		vRetHttpCode=$(curl -s -o "$tmp_file" -w "%{http_code}" -H "${vExtraHeader}" ${vOptInsecure}"$vCurrentRqst")
	else
		vRetHttpCode=$(curl -s -o "$tmp_file" -w "%{http_code}"${vOptInsecure}"$vCurrentRqst")
	fi
	
	vCurlRetCode=$?
	if [ $vCurlRetCode -ne 0 ]; then
		print_error "Erreur lors de la requête HTTP: curl a retourné le code $vCurlRetCode."
		#exit 1
	fi
	
	
	if [ -z "${vArrPerRes[$vRetHttpCode,1]}" ] || [ "${vArrPerRes[$vRetHttpCode,1]}" == "" ] || [ "${vArrPerRes[$vRetHttpCode,1]}" -eq 0 ]; then
		vArrPerRes[$vRetHttpCode,1]=$vRetHttpCode
		vArrPerRes[$vRetHttpCode,2]=0
		if [ $vSumRetCode -gt 0 ]; then
			vRetCodeList="${vRetCodeList} "
		fi
		vRetCodeList="${vRetCodeList}${vRetHttpCode}"
		((vSumRetCode++))
	fi
	vArrPerRes[$vRetHttpCode,2]=$((vArrPerRes[$vRetHttpCode,2] + 1))
	
	# Reprise automatique sur erreur
	if [[ $vRetHttpCode -ne 200 ]]; then
		if [[ $vRecurCallLvl -ge $vRecursLimit ]]; then
			if [ $vQuite -ne 1 ]; then
				echo "Reprise automatique sur erreur ignorée car limite d'appels recursifs atteinte : ${vRecurCallLvl} / ${vRecursLimit} (Requete T${vSubRecurCallLvl} #${vNbRequest}, Code retour : ${vRetHttpCode})"
			fi
		else
			for (( vIdxDicho=1; vIdxDicho<3; vIdxDicho++ ))
			do
				# Construction des URL et alimentation du tableau des requêtes à refaire à la fin
				# L'index 1 va servir à stocker la nature de la tentative
				# L'index 2 va servir à stocker le nombre de paramètres prévus
				vIdxOpt=3
				# On commence par définir les options qui dépendent de la stratégie de récupération
				# Stratégie 1 : c'était une requête groupée : DICHOTOMY (ex. : au lieu de demander 10 résultats d'un coup on demande 5 * 2 résultats)
				if [[ $vStep -gt 1 ]]; then
					vStepDicho1=$(echo "scale=0; $vStep / 2" | bc)
					vStepDicho2=$((vStep - vStepDicho1))
					
					if [[ $vIdxDicho -eq 1 ]]; then
						vStepDicho=$vStepDicho1
					else
						vStepDicho=$vStepDicho2
					fi
					
					if [[ $vStepDicho -gt 0 ]]; then

						vArrPerRes[$vErrorCounter,1]="DICHO${vIdxDicho}"
						vArrPerRes[$vErrorCounter,$vIdxOpt]="-S"
						((vIdxOpt++))
						vArrPerRes[$vErrorCounter,$vIdxOpt]="$vStepDicho"
						((vIdxOpt++))

						vArrPerRes[$vErrorCounter,$vIdxOpt]="-T"
						((vIdxOpt++))
						vArrPerRes[$vErrorCounter,$vIdxOpt]="${vTempo}"
						((vIdxOpt++))

						vArrPerRes[$vErrorCounter,$vIdxOpt]="-U"
						((vIdxOpt++))
						vArrPerRes[$vErrorCounter,$vIdxOpt]="${vURL}"
						((vIdxOpt++))

						if [[ -n "$vURLBU" ]]; then
							vArrPerRes[$vErrorCounter,$vIdxOpt]="-B"
							((vIdxOpt++))
							vArrPerRes[$vErrorCounter,$vIdxOpt]="${vURLBU}"
							((vIdxOpt++))
						fi

						vArrPerRes[$vErrorCounter,$vIdxOpt]="-I"
						((vIdxOpt++))
						vSubOffset=$((vOffset - 1))
						if [[ $vIdxDicho -eq 2 ]]; then
							vSubOffset=$((vSubOffset + vStepDicho1))
						fi
						
						vArrPerRes[$vErrorCounter,$vIdxOpt]="${vSubOffset}"
						((vIdxOpt++))
					fi
				# Stratégies 2 et 3 : (on retente, parfois ça marche)
				else
					vIdxDicho=3 # On a pas besoin de passer deux fois car on ne fait pas de DICHOTOMIE
					
					vArrPerRes[$vErrorCounter,$vIdxOpt]="-S" # Le step reste à 1
					((vIdxOpt++))
					vArrPerRes[$vErrorCounter,$vIdxOpt]="1"
					((vIdxOpt++))
					
					vArrPerRes[$vErrorCounter,$vIdxOpt]="-I"
					((vIdxOpt++))
					vSubOffset=$((vOffset - 1))
					vArrPerRes[$vErrorCounter,$vIdxOpt]="${vSubOffset}"
					((vIdxOpt++))

					if (( vRecurCallLvl % 2 == 1 )) && [[ -n "$vURLBU" ]]; then # Stratégie BACKUP : Une fois sur deux on inverse l'URL et l'URL BACKUP
						vArrPerRes[$vErrorCounter,1]="RETRY_BACKUP"

						vArrPerRes[$vErrorCounter,$vIdxOpt]="-U"
						((vIdxOpt++))
						vArrPerRes[$vErrorCounter,$vIdxOpt]="${vURLBU}"
						((vIdxOpt++))

						vArrPerRes[$vErrorCounter,$vIdxOpt]="-B"
						((vIdxOpt++))
						vArrPerRes[$vErrorCounter,$vIdxOpt]="${vURL}"
						((vIdxOpt++))
					else # L'autre fois sur 2 on retente sans rien changer : Stratégie RETRY
						vArrPerRes[$vErrorCounter,1]="RETRY"

						vArrPerRes[$vErrorCounter,$vIdxOpt]="-U"
						((vIdxOpt++))
						vArrPerRes[$vErrorCounter,$vIdxOpt]="${vURL}"
						((vIdxOpt++))

						if [[ -n "$vURLBU" ]]; then
							vArrPerRes[$vErrorCounter,$vIdxOpt]="-B"
							((vIdxOpt++))
							vArrPerRes[$vErrorCounter,$vIdxOpt]="${vURLBU}"
							((vIdxOpt++))
						fi
					fi
				fi

				if [[ -n "$vArrPerRes[$vErrorCounter,1]" ]]; then
					if [ $vVerbose -eq 1 ]; then
						vArrPerRes[$vErrorCounter,$vIdxOpt]="-v"
						((vIdxOpt++))
					fi
					if [ $vQuite -eq 1 ]; then
						vArrPerRes[$vErrorCounter,$vIdxOpt]="-q"
						((vIdxOpt++))
					fi

					vArrPerRes[$vErrorCounter,$vIdxOpt]="-O"
					((vIdxOpt++))
					vArrPerRes[$vErrorCounter,$vIdxOpt]="${vOut}"
					((vIdxOpt++))

					vArrPerRes[$vErrorCounter,$vIdxOpt]="-L"
					((vIdxOpt++))
					vArrPerRes[$vErrorCounter,$vIdxOpt]="${vLabel}"
					((vIdxOpt++))

					vArrPerRes[$vErrorCounter,$vIdxOpt]="-F"
					((vIdxOpt++))
					vArrPerRes[$vErrorCounter,$vIdxOpt]="${vFormat}"
					((vIdxOpt++))

					vArrPerRes[$vErrorCounter,$vIdxOpt]="-P"
					((vIdxOpt++))
					vArrPerRes[$vErrorCounter,$vIdxOpt]="${vIdxPad}"
					((vIdxOpt++))
					
					vArrPerRes[$vErrorCounter,$vIdxOpt]="-R" # Un unique call
					((vIdxOpt++))
					vArrPerRes[$vErrorCounter,$vIdxOpt]="0"
					((vIdxOpt++))

					if [ -n "$vExtraHeader" ]; then
						vArrPerRes[$vErrorCounter,$vIdxOpt]="-H"
						((vIdxOpt++))
						vArrPerRes[$vErrorCounter,$vIdxOpt]="${vExtraHeader}"
						((vIdxOpt++))
					fi
					if [ $vVerbose -eq 1 ]; then
						echo "Ajout reprise sur erreur suite à code ${vRetHttpCode} lors de la tentative T${vRecurCallLvl}_p${vLblCurrentIdxPage}_${vLastIdxPage} : \"${vArrPerRes[$vErrorCounter,1]}\""
					fi
					vArrPerRes[$vErrorCounter,2]=$((vIdxOpt - 3))
					
					vErrorCounter=$((vErrorCounter + 1))
				fi
			done
		fi
	fi

	# Renommer le fichier temporaire
	vCurrentPageOut="${vLabel}_${vRetHttpCode}_${vLblCurrentStartOffset}_to_${vLblCurrentEndOffset}_T${vRecurCallLvl}_p${vLblCurrentIdxPage}_${vLastIdxPage}_${vExecutionStartDate}.${vFormat}"
	mv "$tmp_file" "${vOut}${vCurrentPageOut}"
	if [ $vQuite -ne 1 ]; then
		echo " - ${vRetHttpCode} -> ${vCurrentPageOut}"
	fi
	# Incrémenter l'index de la page courante et l'offset
	((vCurrentIdxPage++))
	vOffset=$((vOffset + vStep))
	# Incrémenter le nombre de requêtes
	((vNbRequest++))
	
	# Temporisation si nécessaire
	if [ $vCurrentIdxPage -le $vLastIdxPage ] && [ $vTempo -gt 0 ]; then
		if [ $vVerbose -eq 1 ]; then
			echo "sleep $(displayDelayMs $vTempo)"
		fi
		sleep $vTempoSecondes
	fi
done

vEndTimeMs=$(date +%s%3N)
vEndTime=$(date +'%Y-%m-%d %H:%M:%S')
vRunDelay=$(( vEndTimeMs - vStartTimeMs ))

# Partie D : debriefing
if [ $vQuite -ne 1 ]; then
	echo "Date de démarrage du script : ${vStartTime}"
	echo "Date de fin : ${vEndTime}"
	echo "Délais : $(displayDelayMs $vRunDelay)"
	echo "Nombre de requêtes réalisées : ${vNbRequest} / ${vLastIdxPage}"
	for vRetCode in $vRetCodeList; do
		echo "  $vRetCode : ${vArrPerRes[$vRetCode,2]}"
	done
fi

# Partie E : reprise auto

for (( vIdxError=0; vIdxError<vErrorCounter; vIdxError++ ))
do
	vHumanIndex=$(( vIdxError + 1 ))
    # Nature de la tentative de correction automatique
    vCurrentTest=${vArrPerRes[$vIdxError,1]}

    # Nombre d'options
    vNbOpt=${vArrPerRes[$vIdxError,2]}
	# Incrément du nombre de call récursifs
	vSubRecurCallLvl=$((vRecurCallLvl + 1))
	vCurrentCmd=("${0}" "-C" "${vSubRecurCallLvl}")
	
    # Parcours des options
    for (( vOptIdx=1; vOptIdx<=vNbOpt; vOptIdx++ ))
    do
        vCurrentOpt=${vArrPerRes[$vIdxError,$((vOptIdx + 2))]}
		vCurrentCmd+=("${vCurrentOpt}")
    done

    if [ $vVerbose -eq 1 ]; then
		echo "Reprise sur erreur automatique T${vRecurCallLvl} #${vHumanIndex} / ${vErrorCounter}: \"${vCurrentTest}\", options=${vNbOpt} :"
		echo "${vCurrentCmd[*]}"
	fi
	
	vTempoRecall=$(( vTempo + 500 * vRecurCallLvl ))
	vTempoRecallSecondes=$(echo "scale=3; $vTempoRecall / 1000" | bc)
	
	if [ $vVerbose -eq 1 ]; then
		echo "sleep $(displayDelayMs $vTempoRecall)"
	fi
	sleep $vTempoRecallSecondes
	
	# Exécution de la commande construite (eval ne fonctionne pas à cause des espaces entre les arguments)
    "${vCurrentCmd[@]}"
	vRetCode=$?
	if [ $vRetCode -ne 0 ]; then
		print_error "Erreur lors de la reprise sur erreur automatique T${vRecurCallLvl} #${vHumanIndex} / ${vErrorCounter}: \"${vCurrentTest}\", options=${vNbOpt} :"
		print_error "${vCurrentCmd[*]}"
		print_error "Retour : ${vRetCode}"
		#exit 1
	fi
done

