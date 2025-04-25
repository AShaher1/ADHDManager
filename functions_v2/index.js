const {onCall} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const {OpenAI} = require("openai");

// Cloud function to proxy requests to OpenAI API
exports.callOpenAI = onCall({
  enforceAppCheck: false, // Set to true in production for additional security
  maxInstances: 10,
}, async (request) => {
  try {
    logger.info("OpenAI function called", {structuredData: true});
    
    // Get API key from environment variables
    const openaiApiKey = process.env.OPENAI_API_KEY;
    
    if (!openaiApiKey) {
      logger.error("OpenAI API key not found");
      throw new Error("Server configuration error: API key not found");
    }
    
    const openai = new OpenAI({
      apiKey: openaiApiKey
    });

    // Extract parameters from request
    const {model, messages, max_tokens} = request.data;
    
    logger.info("Calling OpenAI with params", {
      model: model || "gpt-3.5-turbo",
      messageCount: messages?.length || 0,
      max_tokens: max_tokens || 500
    });
    
    // Call OpenAI API
    const response = await openai.chat.completions.create({
      model: model || "gpt-3.5-turbo",
      messages: messages || [],
      max_tokens: max_tokens || 500
    });
    
    logger.info("OpenAI response received");
    
    // Return the response
    return {
      result: response.choices[0].message.content,
      usage: response.usage
    };
  } catch (error) {
    logger.error("OpenAI API error:", error);
    throw new Error(`Error calling OpenAI API: ${error.message}`);
  }
});