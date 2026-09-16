// Configuração do cliente Supabase para o Nexus StorageControl
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

export const SUPABASE_URL = 'https://ctycpwdlywxzlwavckmf.supabase.co';
export const SUPABASE_ANON_KEY = 'sb_publishable_Ab2dk2FdbvVUFF5V6L72mQ_f3b7lmCW';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

export function onDOMReady(fn) {
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', fn);
    } else {
        fn();
    }
}
