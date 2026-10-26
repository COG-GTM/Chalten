package com.example.policyterm;

import com.example.policyterm.cli.PolicyTermCli;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Entry point. {@code java -jar policy-term-service.jar} starts the REST API;
 * {@code java -jar policy-term-service.jar cli ...} runs the command-line calculator instead.
 */
@SpringBootApplication
public class PolicyTermServiceApplication {

  public static void main(String[] args) {
    if (args.length > 0 && "cli".equals(args[0])) {
      System.exit(PolicyTermCli.run(java.util.Arrays.copyOfRange(args, 1, args.length), System.out, System.err));
    }
    SpringApplication.run(PolicyTermServiceApplication.class, args);
  }
}
