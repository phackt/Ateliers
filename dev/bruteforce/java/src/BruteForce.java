
public class BruteForce {

	private final static int MAXLENGTH = 2;
	//private final static String ALPHABET = "{$+ }#(<,.)*~];%:!^-/[&|\"?0134679ABCDEFGHIJKLMNOPQRSTUVWYZabdghjknoqtuyz";
	private final static String ALPHABET = "b";
	
	public static void main(String[] args) {
				
		compare("");
	}

	private static void compare(String prefix){
		
		for(int i = 0; i < ALPHABET.length(); i++){
			String pass = prefix + ALPHABET.charAt(i);
			
			Permutation.permutation("", pass + Permutation.IMMUABLE);						
			
			if(pass.length() < MAXLENGTH){
				compare(pass);
			}
		}
	}
}
