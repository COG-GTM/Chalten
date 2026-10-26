package com.example.policyterm.api;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(PolicyTermController.class)
class PolicyTermControllerTest {

  @Autowired
  private MockMvc mockMvc;

  @Test
  void proRataEndpointReturnsEarnedAndUnearned() throws Exception {
    mockMvc.perform(post("/policy-terms/pro-rata").contentType(MediaType.APPLICATION_JSON)
            .content("{\"effectiveDate\":\"2025-01-01\",\"termMonths\":12,\"writtenPremium\":1000,\"cancellationDate\":\"2025-04-11\"}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.daysInForce").value(100))
        .andExpect(jsonPath("$.earnedPremium").value(273.97))
        .andExpect(jsonPath("$.unearnedPremium").value(726.03));
  }

  @Test
  void invalidTermIsABadRequest() throws Exception {
    mockMvc.perform(post("/policy-terms").contentType(MediaType.APPLICATION_JSON)
            .content("{\"effectiveDate\":\"2025-01-01\",\"termMonths\":7}"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error").value("Policy terms must last 6 or 12 months"));
  }
}
