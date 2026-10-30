export default {
  async scheduled(_controller, env) {
    const response = await fetch(`${env.SUPABASE_URL}/rest/v1/rpc/keep_alive`, {
      method: "POST",
      headers: { apikey: env.SUPABASE_KEY },
    });
    if (!response.ok) {
      throw new Error(`keep_alive returned ${response.status}`);
    }
  },
};
