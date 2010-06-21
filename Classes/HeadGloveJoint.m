/*
 Copyright 2009 Kaspars Dancis
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "HeadGloveJoint.h"
#import "Player.h"

static void
cpJointInit(cpJoint *joint, const cpJointClass *klass, cpBody *a, cpBody *b)
{
	joint->klass = klass;
	joint->a = a;
	joint->b = b;
}

static inline cpVect
relative_velocity(cpVect r1, cpVect v1, cpFloat w1, cpVect r2, cpVect v2, cpFloat w2){
	cpVect v1_sum = cpvadd(v1, cpvmult(cpvperp(r1), w1));
	cpVect v2_sum = cpvadd(v2, cpvmult(cpvperp(r2), w2));
	
	return cpvsub(v2_sum, v1_sum);
}

static inline cpFloat
scalar_k(cpBody *a, cpBody *b, cpVect r1, cpVect r2, cpVect n)
{
	cpFloat mass_sum = a->m_inv + b->m_inv;
	cpFloat r1cn = cpvcross(r1, n);
	cpFloat r2cn = cpvcross(r2, n);
	
	return mass_sum + a->i_inv*r1cn*r1cn + b->i_inv*r2cn*r2cn;
}

static inline void
apply_impulses(cpBody *a , cpBody *b, cpVect r1, cpVect r2, cpVect j)
{
	cpBodyApplyImpulse(a, cpvneg(j), r1);
	cpBodyApplyImpulse(b, j, r2);
}

static inline void
apply_bias_impulses(cpBody *a , cpBody *b, cpVect r1, cpVect r2, cpVect j)
{
	cpBodyApplyBiasImpulse(a, cpvneg(j), r1);
	cpBodyApplyBiasImpulse(b, j, r2);
}

static void
headGloveJointPreStep(cpJoint *joint, cpFloat dt_inv)
{
	cpBody *a = joint->a;
	cpBody *b = joint->b;
	cpPinJoint *jnt = (cpPinJoint *)joint;
	
	jnt->r1 = cpvrotate(jnt->anchr1, a->rot);
	jnt->r2 = cpvrotate(jnt->anchr2, b->rot);
	
	cpVect delta = cpvsub(cpvadd(b->p, jnt->r2), cpvadd(a->p, jnt->r1));
	cpFloat dist = cpvlength(delta);
	jnt->n = cpvmult(delta, 1.0f/(dist ? dist : INFINITY));
	
	// calculate mass normal
	jnt->nMass = 1.0f/scalar_k(a, b, jnt->r1, jnt->r2, jnt->n);
	
	// calculate bias velocity
	jnt->bias = -cp_joint_bias_coef*dt_inv*(dist - jnt->dist);
	jnt->jBias = 0.0f;
	
	// apply accumulated impulse
	cpVect j = cpvmult(jnt->n, jnt->jnAcc);
	apply_impulses(a, b, jnt->r1, jnt->r2, j);
}



static void
headGloveJointApplyImpulse(cpJoint *joint)
{
	cpBody *a = joint->a;
	cpBody *b = joint->b;
	
	cpPinJoint *jnt = (cpPinJoint *)joint;
	cpVect n = jnt->n;
	cpVect r1 = jnt->r1;
	cpVect r2 = jnt->r2;
	
	//calculate bias impulse
	cpVect vbr = relative_velocity(r1, a->v_bias, a->w_bias, r2, b->v_bias, b->w_bias);
	cpFloat vbn = cpvdot(vbr, n);
	
	cpFloat jbn = (jnt->bias - vbn)*jnt->nMass;
	jnt->jBias += jbn;
	
	cpVect jb = cpvmult(n, jbn);
	apply_bias_impulses(a, b, jnt->r1, jnt->r2, jb);
	
	// compute relative velocity
	cpVect vr = relative_velocity(r1, a->v, a->w, r2, b->v, b->w);
	cpFloat vrn = cpvdot(vr, n);
	
	// compute normal impulse
	cpFloat jn = -vrn*jnt->nMass;
	jnt->jnAcc =+ jn;
	
	// apply impulse
	cpVect j = cpvmult(n, jn);
	apply_impulses(a, b, jnt->r1, jnt->r2, j);
}


static const cpJointClass headGloveJointClass = {
CP_PIN_JOINT,
headGloveJointPreStep,
headGloveJointApplyImpulse,
};


cpPinJoint *
headGloveJointInit(cpPinJoint *joint, cpBody *a, cpBody *b, cpVect anchr1, cpVect anchr2)
{
	cpJointInit((cpJoint *)joint, &headGloveJointClass, a, b);
	
	joint->anchr1 = anchr1;
	joint->anchr2 = anchr2;
	
	cpVect p1 = cpvadd(a->p, cpvrotate(anchr1, a->rot));
	cpVect p2 = cpvadd(b->p, cpvrotate(anchr2, b->rot));
	joint->dist = cpvlength(cpvsub(p2, p1));
	
	joint->jnAcc = 0.0f;
	
	return joint;
}

cpJoint *
headGloveJointNew(cpBody *a, cpBody *b, cpVect anchr1, cpVect anchr2)
{
	return (cpJoint *)headGloveJointInit(cpPinJointAlloc(), a, b, anchr1, anchr2);
}
