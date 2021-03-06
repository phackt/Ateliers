import java.util.HashSet;
import java.util.Set;

import org.apache.commons.lang3.StringUtils;


public class Permutation {

	//Chaine immuable - l'ordre et le nombre de caractère ne varie pas
	public static final String IMMUABLE = "5e8xXmc5";
	
	private static Set<String> duplicatePermutationSet = new HashSet<String>();
	
	public static void permutation(String prefix, String str) {
		int n = str.length();
		if (n == 0){
			
			//Traitement à effectuer ici
			System.out.println(prefix);
			
			duplicatePermutationSet.add(prefix);

		} else {

			for (int i = 0; i < n; i++) {
				
				if (isValid(i, prefix, String.valueOf(str.charAt(i)), str.substring(0, i) + str.substring(i + 1, n))) {
					permutation(prefix + str.charAt(i), str.substring(0, i) + str.substring(i + 1, n));
				}
			}
		}
	}

	private static boolean isValid(int i, String prefix, String charPermuted, String otherString) {

		//on gère les doublons au niveau des permutations
		String fullPass = prefix + charPermuted + otherString;
		
		if(duplicatePermutationSet.contains(fullPass)){
			//duplicatePermutationSet.remove(fullPass);
			return false;
		} else if (IMMUABLE.contains(charPermuted)) {
							
			for (char charOther : otherString.toCharArray()) {
						
				int indexOtherImmuableChar = getIndex(prefix, String.valueOf(charOther));
				int indexCharPermuted = getIndex(prefix, String.valueOf(charPermuted));
				
				if (indexOtherImmuableChar != -1 && indexCharPermuted > indexOtherImmuableChar) {
					return false;
				}
			}
		}
		
		return true;
	}
	
	private static int getIndex(String prefix, String charForIndex){
		if(IMMUABLE.contains(charForIndex)){
			int nbFoisBefore= StringUtils.countMatches(prefix, charForIndex);
			return StringUtils.ordinalIndexOf(IMMUABLE, charForIndex, nbFoisBefore + 1);
		}else{
			return IMMUABLE.indexOf(charForIndex);
		}
	}
}