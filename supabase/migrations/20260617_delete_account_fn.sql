-- Função chamada pelo utilizador autenticado para apagar a própria conta.
-- SECURITY DEFINER corre com os privilégios do owner (postgres), o que
-- permite apagar de auth.users sem expor a service role key ao cliente.
CREATE OR REPLACE FUNCTION public.delete_my_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  uid  uuid   := auth.uid();
  cids uuid[];
BEGIN
  -- Mensagens de chat: apagar antes das conversas (FK pode não ter CASCADE).
  SELECT ARRAY_AGG(id) INTO cids
    FROM chat_conversations WHERE user_id = uid;

  IF cids IS NOT NULL THEN
    DELETE FROM chat_messages WHERE conversation_id = ANY(cids);
  END IF;

  DELETE FROM chat_conversations  WHERE user_id = uid;
  DELETE FROM chat_usage          WHERE user_id = uid;
  DELETE FROM highlights          WHERE user_id = uid;
  DELETE FROM notes               WHERE user_id = uid;
  DELETE FROM reading_progress    WHERE user_id = uid;
  DELETE FROM user_reading_plans  WHERE user_id = uid;
  DELETE FROM saved_devotionals   WHERE user_id = uid;
  DELETE FROM profiles            WHERE id      = uid;

  -- Apagar o registo de autenticação (requer SECURITY DEFINER).
  DELETE FROM auth.users WHERE id = uid;
END;
$$;

-- Apenas utilizadores autenticados podem invocar esta função.
REVOKE ALL    ON FUNCTION public.delete_my_account() FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.delete_my_account() TO authenticated;
