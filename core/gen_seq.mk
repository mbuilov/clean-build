#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# define 'cb_gen_seq' - generator of sequences: [a-z][a-z][a-z][a-z][a-z]
#  max combinations: 26*26*26*26*26 +  26*26*26*26 + 26*26*26 + 26*26 + 26 = 12.356.630

cb_pat4:=
cb_pat3:=
cb_pat2:=
cb_pat1:=

cb_gen_overflow = $(error overflow in 'cb_gen')

cb_gen4 := cb__4_gen
cb__4_gen = $(eval cb_gen4:=cb_a4_gen)
cb_a4_gen = a$(eval cb_gen4:=cb_b4_gen)
cb_b4_gen = b$(eval cb_gen4:=cb_c4_gen)
cb_c4_gen = c$(eval cb_gen4:=cb_d4_gen)
cb_d4_gen = d$(eval cb_gen4:=cb_e4_gen)
cb_e4_gen = e$(eval cb_gen4:=cb_f4_gen)
cb_f4_gen = f$(eval cb_gen4:=cb_g4_gen)
cb_g4_gen = g$(eval cb_gen4:=cb_h4_gen)
cb_h4_gen = h$(eval cb_gen4:=cb_i4_gen)
cb_i4_gen = i$(eval cb_gen4:=cb_j4_gen)
cb_j4_gen = j$(eval cb_gen4:=cb_k4_gen)
cb_k4_gen = k$(eval cb_gen4:=cb_l4_gen)
cb_l4_gen = l$(eval cb_gen4:=cb_m4_gen)
cb_m4_gen = m$(eval cb_gen4:=cb_n4_gen)
cb_n4_gen = n$(eval cb_gen4:=cb_o4_gen)
cb_o4_gen = o$(eval cb_gen4:=cb_p4_gen)
cb_p4_gen = p$(eval cb_gen4:=cb_q4_gen)
cb_q4_gen = q$(eval cb_gen4:=cb_r4_gen)
cb_r4_gen = r$(eval cb_gen4:=cb_s4_gen)
cb_s4_gen = s$(eval cb_gen4:=cb_t4_gen)
cb_t4_gen = t$(eval cb_gen4:=cb_u4_gen)
cb_u4_gen = u$(eval cb_gen4:=cb_v4_gen)
cb_v4_gen = v$(eval cb_gen4:=cb_w4_gen)
cb_w4_gen = w$(eval cb_gen4:=cb_x4_gen)
cb_x4_gen = x$(eval cb_gen4:=cb_y4_gen)
cb_y4_gen = y$(eval cb_gen4:=cb_z4_gen)
cb_z4_gen = z$(eval cb_gen4:=cb_gen_overflow)

cb_gen3 := cb__3_gen
cb__3_gen = $(eval cb_gen3:=cb_a3_gen)
cb_a3_gen = $(eval cb_pat4:=$($(cb_gen4)))$(cb_pat4)a$(eval cb_gen3:=cb_b3_gen)
cb_b3_gen = $(cb_pat4)b$(eval cb_gen3:=cb_c3_gen)
cb_c3_gen = $(cb_pat4)c$(eval cb_gen3:=cb_d3_gen)
cb_d3_gen = $(cb_pat4)d$(eval cb_gen3:=cb_e3_gen)
cb_e3_gen = $(cb_pat4)e$(eval cb_gen3:=cb_f3_gen)
cb_f3_gen = $(cb_pat4)f$(eval cb_gen3:=cb_g3_gen)
cb_g3_gen = $(cb_pat4)g$(eval cb_gen3:=cb_h3_gen)
cb_h3_gen = $(cb_pat4)h$(eval cb_gen3:=cb_i3_gen)
cb_i3_gen = $(cb_pat4)i$(eval cb_gen3:=cb_j3_gen)
cb_j3_gen = $(cb_pat4)j$(eval cb_gen3:=cb_k3_gen)
cb_k3_gen = $(cb_pat4)k$(eval cb_gen3:=cb_l3_gen)
cb_l3_gen = $(cb_pat4)l$(eval cb_gen3:=cb_m3_gen)
cb_m3_gen = $(cb_pat4)m$(eval cb_gen3:=cb_n3_gen)
cb_n3_gen = $(cb_pat4)n$(eval cb_gen3:=cb_o3_gen)
cb_o3_gen = $(cb_pat4)o$(eval cb_gen3:=cb_p3_gen)
cb_p3_gen = $(cb_pat4)p$(eval cb_gen3:=cb_q3_gen)
cb_q3_gen = $(cb_pat4)q$(eval cb_gen3:=cb_r3_gen)
cb_r3_gen = $(cb_pat4)r$(eval cb_gen3:=cb_s3_gen)
cb_s3_gen = $(cb_pat4)s$(eval cb_gen3:=cb_t3_gen)
cb_t3_gen = $(cb_pat4)t$(eval cb_gen3:=cb_u3_gen)
cb_u3_gen = $(cb_pat4)u$(eval cb_gen3:=cb_v3_gen)
cb_v3_gen = $(cb_pat4)v$(eval cb_gen3:=cb_w3_gen)
cb_w3_gen = $(cb_pat4)w$(eval cb_gen3:=cb_x3_gen)
cb_x3_gen = $(cb_pat4)x$(eval cb_gen3:=cb_y3_gen)
cb_y3_gen = $(cb_pat4)y$(eval cb_gen3:=cb_z3_gen)
cb_z3_gen = $(cb_pat4)z$(eval cb_gen3:=cb_a3_gen)

cb_gen2 := cb__2_gen
cb__2_gen = $(eval cb_gen2:=cb_a2_gen)
cb_a2_gen = $(eval cb_pat3:=$($(cb_gen3)))$(cb_pat3)a$(eval cb_gen2:=cb_b2_gen)
cb_b2_gen = $(cb_pat3)b$(eval cb_gen2:=cb_c2_gen)
cb_c2_gen = $(cb_pat3)c$(eval cb_gen2:=cb_d2_gen)
cb_d2_gen = $(cb_pat3)d$(eval cb_gen2:=cb_e2_gen)
cb_e2_gen = $(cb_pat3)e$(eval cb_gen2:=cb_f2_gen)
cb_f2_gen = $(cb_pat3)f$(eval cb_gen2:=cb_g2_gen)
cb_g2_gen = $(cb_pat3)g$(eval cb_gen2:=cb_h2_gen)
cb_h2_gen = $(cb_pat3)h$(eval cb_gen2:=cb_i2_gen)
cb_i2_gen = $(cb_pat3)i$(eval cb_gen2:=cb_j2_gen)
cb_j2_gen = $(cb_pat3)j$(eval cb_gen2:=cb_k2_gen)
cb_k2_gen = $(cb_pat3)k$(eval cb_gen2:=cb_l2_gen)
cb_l2_gen = $(cb_pat3)l$(eval cb_gen2:=cb_m2_gen)
cb_m2_gen = $(cb_pat3)m$(eval cb_gen2:=cb_n2_gen)
cb_n2_gen = $(cb_pat3)n$(eval cb_gen2:=cb_o2_gen)
cb_o2_gen = $(cb_pat3)o$(eval cb_gen2:=cb_p2_gen)
cb_p2_gen = $(cb_pat3)p$(eval cb_gen2:=cb_q2_gen)
cb_q2_gen = $(cb_pat3)q$(eval cb_gen2:=cb_r2_gen)
cb_r2_gen = $(cb_pat3)r$(eval cb_gen2:=cb_s2_gen)
cb_s2_gen = $(cb_pat3)s$(eval cb_gen2:=cb_t2_gen)
cb_t2_gen = $(cb_pat3)t$(eval cb_gen2:=cb_u2_gen)
cb_u2_gen = $(cb_pat3)u$(eval cb_gen2:=cb_v2_gen)
cb_v2_gen = $(cb_pat3)v$(eval cb_gen2:=cb_w2_gen)
cb_w2_gen = $(cb_pat3)w$(eval cb_gen2:=cb_x2_gen)
cb_x2_gen = $(cb_pat3)x$(eval cb_gen2:=cb_y2_gen)
cb_y2_gen = $(cb_pat3)y$(eval cb_gen2:=cb_z2_gen)
cb_z2_gen = $(cb_pat3)z$(eval cb_gen2:=cb_a2_gen)

cb_gen1 := cb__1_gen
cb__1_gen = $(eval cb_gen1:=cb_a1_gen)
cb_a1_gen = $(eval cb_pat2:=$($(cb_gen2)))$(cb_pat2)a$(eval cb_gen1:=cb_b1_gen)
cb_b1_gen = $(cb_pat2)b$(eval cb_gen1:=cb_c1_gen)
cb_c1_gen = $(cb_pat2)c$(eval cb_gen1:=cb_d1_gen)
cb_d1_gen = $(cb_pat2)d$(eval cb_gen1:=cb_e1_gen)
cb_e1_gen = $(cb_pat2)e$(eval cb_gen1:=cb_f1_gen)
cb_f1_gen = $(cb_pat2)f$(eval cb_gen1:=cb_g1_gen)
cb_g1_gen = $(cb_pat2)g$(eval cb_gen1:=cb_h1_gen)
cb_h1_gen = $(cb_pat2)h$(eval cb_gen1:=cb_i1_gen)
cb_i1_gen = $(cb_pat2)i$(eval cb_gen1:=cb_j1_gen)
cb_j1_gen = $(cb_pat2)j$(eval cb_gen1:=cb_k1_gen)
cb_k1_gen = $(cb_pat2)k$(eval cb_gen1:=cb_l1_gen)
cb_l1_gen = $(cb_pat2)l$(eval cb_gen1:=cb_m1_gen)
cb_m1_gen = $(cb_pat2)m$(eval cb_gen1:=cb_n1_gen)
cb_n1_gen = $(cb_pat2)n$(eval cb_gen1:=cb_o1_gen)
cb_o1_gen = $(cb_pat2)o$(eval cb_gen1:=cb_p1_gen)
cb_p1_gen = $(cb_pat2)p$(eval cb_gen1:=cb_q1_gen)
cb_q1_gen = $(cb_pat2)q$(eval cb_gen1:=cb_r1_gen)
cb_r1_gen = $(cb_pat2)r$(eval cb_gen1:=cb_s1_gen)
cb_s1_gen = $(cb_pat2)s$(eval cb_gen1:=cb_t1_gen)
cb_t1_gen = $(cb_pat2)t$(eval cb_gen1:=cb_u1_gen)
cb_u1_gen = $(cb_pat2)u$(eval cb_gen1:=cb_v1_gen)
cb_v1_gen = $(cb_pat2)v$(eval cb_gen1:=cb_w1_gen)
cb_w1_gen = $(cb_pat2)w$(eval cb_gen1:=cb_x1_gen)
cb_x1_gen = $(cb_pat2)x$(eval cb_gen1:=cb_y1_gen)
cb_y1_gen = $(cb_pat2)y$(eval cb_gen1:=cb_z1_gen)
cb_z1_gen = $(cb_pat2)z$(eval cb_gen1:=cb_a1_gen)

cb_gen := cb_a_gen
cb_a_gen = $(eval cb_pat1:=$($(cb_gen1)))$(cb_pat1)a$(eval cb_gen:=cb_b_gen)
cb_b_gen = $(cb_pat1)b$(eval cb_gen:=cb_c_gen)
cb_c_gen = $(cb_pat1)c$(eval cb_gen:=cb_d_gen)
cb_d_gen = $(cb_pat1)d$(eval cb_gen:=cb_e_gen)
cb_e_gen = $(cb_pat1)e$(eval cb_gen:=cb_f_gen)
cb_f_gen = $(cb_pat1)f$(eval cb_gen:=cb_g_gen)
cb_g_gen = $(cb_pat1)g$(eval cb_gen:=cb_h_gen)
cb_h_gen = $(cb_pat1)h$(eval cb_gen:=cb_i_gen)
cb_i_gen = $(cb_pat1)i$(eval cb_gen:=cb_j_gen)
cb_j_gen = $(cb_pat1)j$(eval cb_gen:=cb_k_gen)
cb_k_gen = $(cb_pat1)k$(eval cb_gen:=cb_l_gen)
cb_l_gen = $(cb_pat1)l$(eval cb_gen:=cb_m_gen)
cb_m_gen = $(cb_pat1)m$(eval cb_gen:=cb_n_gen)
cb_n_gen = $(cb_pat1)n$(eval cb_gen:=cb_o_gen)
cb_o_gen = $(cb_pat1)o$(eval cb_gen:=cb_p_gen)
cb_p_gen = $(cb_pat1)p$(eval cb_gen:=cb_q_gen)
cb_q_gen = $(cb_pat1)q$(eval cb_gen:=cb_r_gen)
cb_r_gen = $(cb_pat1)r$(eval cb_gen:=cb_s_gen)
cb_s_gen = $(cb_pat1)s$(eval cb_gen:=cb_t_gen)
cb_t_gen = $(cb_pat1)t$(eval cb_gen:=cb_u_gen)
cb_u_gen = $(cb_pat1)u$(eval cb_gen:=cb_v_gen)
cb_v_gen = $(cb_pat1)v$(eval cb_gen:=cb_w_gen)
cb_w_gen = $(cb_pat1)w$(eval cb_gen:=cb_x_gen)
cb_x_gen = $(cb_pat1)x$(eval cb_gen:=cb_y_gen)
cb_y_gen = $(cb_pat1)y$(eval cb_gen:=cb_z_gen)
cb_z_gen = $(cb_pat1)z$(eval cb_gen:=cb_a_gen)

# generate next sequence 
ifndef cb_checking
cb_gen_seq = $($(cb_gen))
else
$(eval cb_a3_gen = $(subst $$(cb_pat4),$$(call set_global,cb_pat4 cb_gen4)$$(cb_pat4),$(value cb_a3_gen)))
$(eval cb_a2_gen = $(subst $$(cb_pat3),$$(call set_global,cb_pat3 cb_gen3)$$(cb_pat3),$(value cb_a2_gen)))
$(eval cb_a1_gen = $(subst $$(cb_pat2),$$(call set_global,cb_pat2 cb_gen2)$$(cb_pat2),$(value cb_a1_gen)))
$(eval cb_a_gen = $(subst $$(cb_pat1),$$(call set_global,cb_pat1 cb_gen1)$$(cb_pat1),$(value cb_a_gen)))
cb_gen_seq = $($(cb_gen))$(call set_global,cb_gen)
endif

# makefile parsing first phase variables
cb_first_phase_vars += \
  cb_pat4 cb_pat3 cb_pat2 cb_pat1 cb_gen_overflow \
  cb_gen4 cb__4_gen \
  cb_a4_gen cb_b4_gen cb_c4_gen cb_d4_gen cb_e4_gen cb_f4_gen cb_g4_gen cb_h4_gen cb_i4_gen cb_j4_gen cb_k4_gen cb_l4_gen cb_m4_gen \
  cb_n4_gen cb_o4_gen cb_p4_gen cb_q4_gen cb_r4_gen cb_s4_gen cb_t4_gen cb_u4_gen cb_v4_gen cb_w4_gen cb_x4_gen cb_y4_gen cb_z4_gen \
  cb_gen3 cb__3_gen \
  cb_a3_gen cb_b3_gen cb_c3_gen cb_d3_gen cb_e3_gen cb_f3_gen cb_g3_gen cb_h3_gen cb_i3_gen cb_j3_gen cb_k3_gen cb_l3_gen cb_m3_gen \
  cb_n3_gen cb_o3_gen cb_p3_gen cb_q3_gen cb_r3_gen cb_s3_gen cb_t3_gen cb_u3_gen cb_v3_gen cb_w3_gen cb_x3_gen cb_y3_gen cb_z3_gen \
  cb_gen2 cb__2_gen \
  cb_a2_gen cb_b2_gen cb_c2_gen cb_d2_gen cb_e2_gen cb_f2_gen cb_g2_gen cb_h2_gen cb_i2_gen cb_j2_gen cb_k2_gen cb_l2_gen cb_m2_gen \
  cb_n2_gen cb_o2_gen cb_p2_gen cb_q2_gen cb_r2_gen cb_s2_gen cb_t2_gen cb_u2_gen cb_v2_gen cb_w2_gen cb_x2_gen cb_y2_gen cb_z2_gen \
  cb_gen1 cb__1_gen \
  cb_a1_gen cb_b1_gen cb_c1_gen cb_d1_gen cb_e1_gen cb_f1_gen cb_g1_gen cb_h1_gen cb_i1_gen cb_j1_gen cb_k1_gen cb_l1_gen cb_m1_gen \
  cb_n1_gen cb_o1_gen cb_p1_gen cb_q1_gen cb_r1_gen cb_s1_gen cb_t1_gen cb_u1_gen cb_v1_gen cb_w1_gen cb_x1_gen cb_y1_gen cb_z1_gen \
  cb_gen \
  cb_a_gen cb_b_gen cb_c_gen cb_d_gen cb_e_gen cb_f_gen cb_g_gen cb_h_gen cb_i_gen cb_j_gen cb_k_gen cb_l_gen cb_m_gen \
  cb_n_gen cb_o_gen cb_p_gen cb_q_gen cb_r_gen cb_s_gen cb_t_gen cb_u_gen cb_v_gen cb_w_gen cb_x_gen cb_y_gen cb_z_gen \
  cb_gen_seq

# protect macros from modifications in target makefiles,
# do not trace calls to these macros
$(call set_global, \
  cb_pat4 cb_pat3 cb_pat2 cb_pat1 cb_gen_overflow \
  cb_gen4 cb__4_gen \
  cb_a4_gen cb_b4_gen cb_c4_gen cb_d4_gen cb_e4_gen cb_f4_gen cb_g4_gen cb_h4_gen cb_i4_gen cb_j4_gen cb_k4_gen cb_l4_gen cb_m4_gen \
  cb_n4_gen cb_o4_gen cb_p4_gen cb_q4_gen cb_r4_gen cb_s4_gen cb_t4_gen cb_u4_gen cb_v4_gen cb_w4_gen cb_x4_gen cb_y4_gen cb_z4_gen \
  cb_gen3 cb__3_gen \
  cb_a3_gen cb_b3_gen cb_c3_gen cb_d3_gen cb_e3_gen cb_f3_gen cb_g3_gen cb_h3_gen cb_i3_gen cb_j3_gen cb_k3_gen cb_l3_gen cb_m3_gen \
  cb_n3_gen cb_o3_gen cb_p3_gen cb_q3_gen cb_r3_gen cb_s3_gen cb_t3_gen cb_u3_gen cb_v3_gen cb_w3_gen cb_x3_gen cb_y3_gen cb_z3_gen \
  cb_gen2 cb__2_gen \
  cb_a2_gen cb_b2_gen cb_c2_gen cb_d2_gen cb_e2_gen cb_f2_gen cb_g2_gen cb_h2_gen cb_i2_gen cb_j2_gen cb_k2_gen cb_l2_gen cb_m2_gen \
  cb_n2_gen cb_o2_gen cb_p2_gen cb_q2_gen cb_r2_gen cb_s2_gen cb_t2_gen cb_u2_gen cb_v2_gen cb_w2_gen cb_x2_gen cb_y2_gen cb_z2_gen \
  cb_gen1 cb__1_gen \
  cb_a1_gen cb_b1_gen cb_c1_gen cb_d1_gen cb_e1_gen cb_f1_gen cb_g1_gen cb_h1_gen cb_i1_gen cb_j1_gen cb_k1_gen cb_l1_gen cb_m1_gen \
  cb_n1_gen cb_o1_gen cb_p1_gen cb_q1_gen cb_r1_gen cb_s1_gen cb_t1_gen cb_u1_gen cb_v1_gen cb_w1_gen cb_x1_gen cb_y1_gen cb_z1_gen \
  cb_gen \
  cb_a_gen cb_b_gen cb_c_gen cb_d_gen cb_e_gen cb_f_gen cb_g_gen cb_h_gen cb_i_gen cb_j_gen cb_k_gen cb_l_gen cb_m_gen \
  cb_n_gen cb_o_gen cb_p_gen cb_q_gen cb_r_gen cb_s_gen cb_t_gen cb_u_gen cb_v_gen cb_w_gen cb_x_gen cb_y_gen cb_z_gen)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: cb_gen_seq
$(call set_global,cb_gen_seq,cb_gen_seq)
